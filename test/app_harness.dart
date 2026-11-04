import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/main.dart';
import 'package:redix/words/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The words the fake API serves: each key's value names its language and key, so a test reads which word is shown.
Map<String, String> wordsIn(String language) => {
  for (final key in [
    'app.title', 'app.subtitle',
    'signIn.username', 'signIn.password', 'signIn.hint', 'signIn.submit', 'signIn.forgotPassword',
    'signIn.invalidCredentials', 'signIn.accountLocked', 'signIn.sessionExpired', 'signIn.noConnection',
    'changePassword.title', 'changePassword.hint', 'changePassword.current', 'changePassword.new', 'changePassword.confirm',
    'changePassword.submit', 'changePassword.mismatch', 'changePassword.invalidCredentials', 'changePassword.accountLocked',
    'changePassword.weakPassword', 'changePassword.noConnection',
    'myAccount.title', 'myAccount.language', 'myAccount.arabic', 'myAccount.english', 'myAccount.languageNeedsNetwork',
    'myAccount.changePassword',
    'settings.title', 'projects.title', 'projects.new', 'projects.empty', 'projects.loadFailed', 'common.retry', 'projects.running',
    'projects.finished', 'projects.readOnly', 'projects.startDate', 'projects.name', 'projects.units', 'projects.noUnits',
    'projects.unitName', 'projects.addUnit', 'projects.removeUnit', 'projects.create', 'common.cancel', 'projects.close',
    'projects.closeQuestion', 'projects.closeExplain', 'projects.invalidName', 'projects.projectFinished', 'projects.noConnection',
    'projects.refused',
    'users.title', 'users.new', 'users.loadFailed', 'users.owner', 'users.disabled', 'users.edit', 'users.resetPassword', 'users.disable',
    'users.enable', 'users.name', 'users.nameHint', 'users.username', 'users.mobile', 'users.temporaryPassword',
    'users.temporaryPasswordHint', 'users.add', 'users.save', 'users.disableQuestion', 'users.disableExplain', 'users.resetExplain',
    'users.invalidName', 'users.invalidUsername', 'users.invalidMobile', 'users.usernameTaken', 'users.weakPassword',
    'users.ownerCannotBeDisabled', 'users.noConnection', 'users.refused',
  ])
    key: '$language $key',
};

/// A kept session, as the secure storage holds it after a sign-in.
const keptSession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false}';

/// A kept session whose password is temporary.
const keptTemporarySession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": true}';

/// A kept session of an owner.
const keptOwnerSession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "isOwner": true}';

/// The API as the app's tests see it: words for any language, and the answers of sign-in, refresh and password change each test chooses.
class FakeApi {
  /// Whether the network is up; when false every request fails like a phone without signal.
  var online = true;

  /// The status and problem code `POST /auth/sign-in` answers; 200 opens a session.
  var signInAnswer = (status: 200, code: '');

  /// Whether the user's password is temporary: sign-in and refresh report it, and a successful change clears it.
  var mustChangePassword = false;

  /// The status `POST /auth/refresh` answers; 200 renews the session.
  var refreshStatus = 200;

  /// The status and problem code `POST /auth/change-password` answers; 200 changes the password.
  var changePasswordAnswer = (status: 200, code: '');

  /// Whether the signed-in user is an owner: every session says so.
  var isOwner = false;

  /// The projects the API holds, as it answers them.
  final projects = <Map<String, Object>>[];

  /// The status and problem code the API answers to a change of a project; 2xx makes the change. An empty code sends none.
  var projectAnswer = (status: 200, code: '');

  /// The changes of a project the app sent, as `path` and body.
  final sentProjectChanges = <(String, Map<String, dynamic>)>[];

  /// The users the API holds, as it answers them.
  final users = <Map<String, Object>>[];

  /// The status and problem code the API answers to a change of a user; 2xx makes the change. An empty code sends none.
  var userAnswer = (status: 200, code: '');

  /// The changes of a user the app sent, as `path` and body.
  final sentUserChanges = <(String, Map<String, dynamic>)>[];

  /// Access tokens the API treats as expired, answering 401 with no body.
  final expiredAccessTokens = <String>{};

  /// The access tokens the app sent, in order.
  final sentAccessTokens = <String>[];

  /// The client the app's requests reach.
  late final client = MockClient((request) async {
    if (!online) {
      throw http.ClientException('offline');
    }
    final path = request.url.path;
    if (path.startsWith('/translations/')) {
      return http.Response.bytes(utf8.encode(jsonEncode(wordsIn(request.url.pathSegments.last))), 200, headers: {'etag': '"1"'});
    }
    final accessToken = (request.headers['Authorization'] ?? '').replaceFirst('Bearer ', '');
    if (path == '/auth/change-password' || path.startsWith('/projects') || path.startsWith('/users')) {
      sentAccessTokens.add(accessToken);
      if (expiredAccessTokens.contains(accessToken)) {
        return http.Response('', 401);
      }
    }
    if (path.startsWith('/projects')) {
      return _answerProjects(request);
    }
    if (path.startsWith('/users')) {
      return _answerUsers(request);
    }
    final (status, code) = switch (path) {
      '/auth/sign-in' => (signInAnswer.status, signInAnswer.code),
      '/auth/refresh' => (refreshStatus, 'sessionExpired'),
      _ => (changePasswordAnswer.status, changePasswordAnswer.code),
    };
    if (path == '/auth/change-password' && status == 200) {
      mustChangePassword = false;
    }
    final body = status == 200
        ? '{"accessToken": "new-access", "refreshToken": "new-refresh", "mustChangePassword": $mustChangePassword, "isOwner": $isOwner}'
        : '{"code": "$code"}';
    return http.Response(body, status);
  });

  /// Adds a project to what the API holds, with [units] named in order.
  Map<String, Object> addProject(String name, {String status = 'running', String startDate = '2026-03-01', List<String> units = const []}) {
    final id = 'project-${projects.length}';
    final project = <String, Object>{
      'id': id,
      'name': name,
      'startDate': startDate,
      'status': status,
      'units': [for (final (index, unit) in units.indexed) {'id': '$id-unit-$index', 'name': unit}],
    };
    projects.add(project);
    return project;
  }

  /// Adds a user to what the API holds.
  Map<String, Object> addUser(String displayName, {required String username, String mobile = '', bool isOwner = false, bool isActive = true}) {
    final user = <String, Object>{
      'id': 'user-${users.length}',
      'username': username,
      'displayName': displayName,
      'mobile': mobile,
      'isOwner': isOwner,
      'isActive': isActive,
      'mustChangePassword': false,
    };
    users.add(user);
    return user;
  }

  http.Response _answerUsers(http.Request request) {
    if (request.method == 'GET') {
      return _json(users, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final path = request.url.path;
    sentUserChanges.add((path, body));
    if (userAnswer.status >= 300) {
      return _json({if (userAnswer.code.isNotEmpty) 'code': userAnswer.code}, userAnswer.status);
    }
    if (path == '/users') {
      return _json(addUser(body['displayName'] as String, username: body['username'] as String, mobile: body['mobile'] as String), 201);
    }
    final user = users.singleWhere((user) => user['id'] == request.url.pathSegments[1]);
    if (path.endsWith('/disable')) {
      user['isActive'] = false;
    } else if (path.endsWith('/enable')) {
      user['isActive'] = true;
    } else if (!path.endsWith('/reset-password')) {
      user['displayName'] = body['displayName'] as String;
      user['mobile'] = body['mobile'] as String;
    }
    return _json(user, 200);
  }

  /// Answers as bytes with no character set, as a JSON reply may arrive, so reading Arabic takes UTF-8 on the app's side.
  http.Response _json(Object body, int status) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

  http.Response _answerProjects(http.Request request) {
    if (request.method == 'GET') {
      return _json(projects, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final path = request.url.path;
    sentProjectChanges.add((path, body));
    if (projectAnswer.status >= 300) {
      return _json({if (projectAnswer.code.isNotEmpty) 'code': projectAnswer.code}, projectAnswer.status);
    }
    if (path == '/projects') {
      return _json(addProject(body['name'] as String, startDate: body['startDate'] as String, units: (body['units'] as List<dynamic>).cast<String>()), 201);
    }
    final project = projects.singleWhere((project) => project['id'] == request.url.pathSegments[1]);
    if (path.endsWith('/close')) {
      project['status'] = 'finished';
    } else {
      final units = project['units'] as List<Map<String, String>>;
      units.add({'id': '${project['id']}-unit-${units.length}', 'name': body['name'] as String});
    }
    return _json(project, 200);
  }
}

/// The words of [language] as the phone keeps them after an earlier start.
Map<String, Object> keptWords(String language) => {'words': jsonEncode({'language': language, 'etag': '"1"', 'words': wordsIn(language)})};

/// Starts the app on a phone in [locale], with [stored] in its secure storage and [preferences] kept, talking to [api].
Future<Session> pumpRedix(
  WidgetTester tester,
  FakeApi api, {
  Locale locale = const Locale('en'),
  Map<String, String> stored = const {},
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  FlutterSecureStorage.setMockInitialValues(Map.of(stored));
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final session = Session();
  final language = AppLanguage();
  await http.runWithClient(() async {
    await session.restore();
    await language.restore();
    await tester.pumpWidget(RedixApp(session: session, language: language));
    await tester.pumpAndSettle();
  }, () => api.client);
  return session;
}

/// Runs [action] and lets the app settle, with the app's requests reaching [api].
Future<void> act(WidgetTester tester, FakeApi api, Future<void> Function() action) => http.runWithClient(() async {
  await action();
  await tester.pumpAndSettle();
}, () => api.client);
