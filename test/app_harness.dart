import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/main.dart';
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
  ])
    key: '$language $key',
};

/// A kept session, as the secure storage holds it after a sign-in.
const keptSession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false}';

/// A kept session whose password is temporary.
const keptTemporarySession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": true}';

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
    if (path == '/auth/change-password') {
      sentAccessTokens.add(accessToken);
      if (expiredAccessTokens.contains(accessToken)) {
        return http.Response('', 401);
      }
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
        ? '{"accessToken": "new-access", "refreshToken": "new-refresh", "mustChangePassword": $mustChangePassword}'
        : '{"code": "$code"}';
    return http.Response(body, status);
  });
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
  await http.runWithClient(() async {
    await session.restore();
    await tester.pumpWidget(RedixApp(session: session));
    await tester.pumpAndSettle();
  }, () => api.client);
  return session;
}

/// Runs [action] and lets the app settle, with the app's requests reaching [api].
Future<void> act(WidgetTester tester, FakeApi api, Future<void> Function() action) => http.runWithClient(() async {
  await action();
  await tester.pumpAndSettle();
}, () => api.client);
