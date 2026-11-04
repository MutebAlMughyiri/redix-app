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
    'users.roles', 'users.rolesHint', 'users.roleManager', 'users.roleFinance', 'users.roleField', 'users.roleReader', 'users.noProjects',
    'users.addExisting', 'users.unknownUser', 'users.invalidRole', 'users.lastManager', 'users.otherProject',
    'myAccount.changePassword', 'myAccount.signOut', 'myAccount.signOutQuestion', 'myAccount.signOutExplain',
    'settings.title', 'projects.title', 'projects.new', 'projects.empty', 'projects.loadFailed', 'common.retry', 'projects.running',
    'projects.finished', 'projects.readOnly', 'projects.startDate', 'projects.name', 'projects.units', 'projects.noUnits',
    'projects.unitName', 'projects.addUnit', 'projects.removeUnit', 'projects.create', 'common.cancel', 'projects.close',
    'projects.closeQuestion', 'projects.closeExplain', 'projects.invalidName', 'projects.projectFinished', 'projects.noConnection',
    'projects.refused',
    'users.title', 'users.new', 'users.loadFailed', 'users.disabled', 'users.edit', 'users.resetPassword', 'users.disable',
    'users.enable', 'users.name', 'users.nameHint', 'users.username', 'users.mobile', 'users.temporaryPassword',
    'users.temporaryPasswordHint', 'users.add', 'users.save', 'users.disableQuestion', 'users.disableExplain', 'users.resetExplain',
    'users.invalidName', 'users.invalidUsername', 'users.invalidMobile', 'users.usernameTaken', 'users.weakPassword',
    'users.noConnection', 'users.refused',
  ])
    key: '$language $key',
};

/// A kept session, as the secure storage holds it after a sign-in.
const keptSession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false}';

/// A kept session whose password is temporary.
const keptTemporarySession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": true}';

/// What a system admin holds everywhere.
const systemAdmin = ['startProject', 'manageLogins'];

/// What a project manager who also does the finance may do in a project.
const managerAndFinance = ['manageUsers', 'readProject', 'seeAllCapital', 'manageProject'];

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

  /// What the signed-in user holds everywhere: every session says so.
  var permissions = <String>[];

  /// The roles a project can give, in their order.
  final roles = <Map<String, String>>[
    {'id': 'role-manager', 'wordKey': 'users.roleManager'},
    {'id': 'role-finance', 'wordKey': 'users.roleFinance'},
    {'id': 'role-field', 'wordKey': 'users.roleField'},
    {'id': 'role-reader', 'wordKey': 'users.roleReader'},
  ];

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

  /// How many times the app told the API it signed out.
  var signOuts = 0;

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
    if (path == '/auth/sign-out') {
      signOuts++;
      return http.Response('', 204);
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
        ? '{"accessToken": "new-access", "refreshToken": "new-refresh", "mustChangePassword": $mustChangePassword, "permissions": ${jsonEncode(permissions)}}'
        : '{"code": "$code"}';
    return http.Response(body, status);
  });

  /// Adds a project to what the API holds, with [units] named in order.
  Map<String, Object> addProject(
    String name, {
    String status = 'running',
    String startDate = '2026-03-01',
    List<String> units = const [],
    List<String> roles = const ['users.roleManager', 'users.roleFinance'],
    List<String> permissions = managerAndFinance,
  }) {
    final id = 'project-${projects.length}';
    final project = <String, Object>{
      'id': id,
      'name': name,
      'startDate': startDate,
      'status': status,
      'units': [for (final (index, unit) in units.indexed) {'id': '$id-unit-$index', 'name': unit}],
      'roles': roles,
      'permissions': permissions,
    };
    projects.add(project);
    return project;
  }

  /// Adds a user to what the API holds.
  Map<String, Object> addUser(String displayName, {required String username, String mobile = '', bool isActive = true}) {
    final user = <String, Object>{
      'id': 'user-${users.length}',
      'username': username,
      'displayName': displayName,
      'mobile': mobile,
      'isActive': isActive,
      'mustChangePassword': false,
      'projects': <Map<String, Object>>[],
    };
    users.add(user);
    return user;
  }

  /// Gives [user], as [addUser] answered them, a role in the project [projectId].
  void giveRole(Map<String, Object> user, String projectId, String roleId) {
    final project = projects.singleWhere((project) => project['id'] == projectId);
    final role = roles.singleWhere((role) => role['id'] == roleId);
    (user['projects'] as List<Map<String, Object>>).add({'projectId': projectId, 'name': project['name'] as String, 'role': role});
  }

  /// [user] as a project's list answers them: only that project's lines.
  Map<String, Object> _inProject(Map<String, Object> user, String projectId) => {
    ...user,
    'projects': (user['projects'] as List<Map<String, Object>>).where((line) => line['projectId'] == projectId).toList(),
  };

  http.Response _answerProjectUsers(http.Request request, String projectId) {
    final segments = request.url.pathSegments;
    if (request.method == 'GET') {
      final inProject = users.where((user) => (_inProject(user, projectId)['projects'] as List<Map<String, Object>>).isNotEmpty);
      return _json([for (final user in inProject) _inProject(user, projectId)], 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentUserChanges.add((request.url.path, body));
    if (userAnswer.status >= 300) {
      return _json({if (userAnswer.code.isNotEmpty) 'code': userAnswer.code}, userAnswer.status);
    }
    if (segments.length == 3) {
      final user = addUser(body['displayName'] as String, username: body['username'] as String, mobile: body['mobile'] as String);
      giveRole(user, projectId, roles.last['id']!);
      return _json(_inProject(user, projectId), 201);
    }
    if (segments[3] == 'existing') {
      final user = users.singleWhere((user) => user['username'] == body['username']);
      giveRole(user, projectId, roles.last['id']!);
      return _json(_inProject(user, projectId), 200);
    }
    final user = users.singleWhere((user) => user['id'] == segments[3]);
    if (segments.last == 'remove') {
      (user['projects'] as List<Map<String, Object>>).removeWhere((line) => line['projectId'] == projectId && (line['role']! as Map<String, String>)['id'] == segments[5]);
    } else {
      giveRole(user, projectId, segments[5]);
    }
    return _json(_inProject(user, projectId), 200);
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
    final segments = request.url.pathSegments;
    final user = users.singleWhere((user) => user['id'] == segments[1]);
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
    final segments = request.url.pathSegments;
    if (segments.length >= 3 && segments[2] == 'roles') {
      return _json(roles, 200);
    }
    if (segments.length >= 3 && segments[2] == 'users') {
      return _answerProjectUsers(request, segments[1]);
    }
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
