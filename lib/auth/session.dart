import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api.dart';

/// The signed-in session (UC-002): the tokens the API issued, kept only in the Keychain or Keystore (NFR-09), and the one way to call the API as the user.
class Session extends ChangeNotifier {
  /// A session kept in the device's secure storage, the Keychain or Keystore.
  Session([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const _storageKey = 'session';

  var _accessToken = '';
  var _refreshToken = '';
  var _mustChangePassword = false;
  var _notice = '';

  /// True from sign-in until the session ends.
  bool get isOpen => _refreshToken.isNotEmpty;

  /// The token sent with each request to the API; renewed with the refresh token.
  String get accessToken => _accessToken;

  /// True while the password is a temporary one that must be changed before anything else (UC-003).
  bool get mustChangePassword => _mustChangePassword;

  /// The word key of why the last session ended, for the sign-in screen; empty when there is nothing to say.
  String get notice => _notice;

  /// Reads the session kept from an earlier sign-in, then renews it in the background. A session the API refuses ends, with a notice;
  /// without a network the kept session stays open, so the app works offline (FR-16).
  Future<void> restore() async {
    _apply(jsonDecode(await _storage.read(key: _storageKey) ?? '{}') as Map<String, dynamic>);
    notifyListeners();
    if (isOpen) {
      unawaited(_renew());
    }
  }

  /// Signs in with [username] and [password] (FR-01). Returns an empty string once the session is open, otherwise the word key of the
  /// refusal: `signIn.invalidCredentials`, `signIn.accountLocked` or `signIn.noConnection`.
  Future<String> signIn(String username, String password) async {
    try {
      final response = await http.post(apiUri('/auth/sign-in'), headers: jsonHeaders, body: jsonEncode({'username': username, 'password': password}));
      if (response.statusCode != 200) {
        return 'signIn.${(jsonDecode(response.body) as Map<String, dynamic>)['code']}';
      }
      _notice = '';
      await _keep(response);
      return '';
    } on Exception catch (error) {
      debugPrint('Sign-in failed: $error');
      return 'signIn.noConnection';
    }
  }

  /// Replaces the password (UC-003): ends the forced change of a temporary one and signs out the user's other phones. Returns an empty string
  /// once changed, otherwise the word key of the refusal: `changePassword.invalidCredentials`, `changePassword.accountLocked`,
  /// `changePassword.weakPassword` or `changePassword.noConnection`.
  Future<String> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await post('/auth/change-password', {'currentPassword': currentPassword, 'newPassword': newPassword});
      if (response.statusCode != 200) {
        return 'changePassword.${(jsonDecode(response.body) as Map<String, dynamic>)['code']}';
      }
      await _keep(response);
      return '';
    } on Exception catch (error) {
      debugPrint('Password not changed: $error');
      return 'changePassword.noConnection';
    }
  }

  /// Sends [body] as JSON to the API [path] as the signed-in user. An expired access token is renewed once and the request sent again;
  /// a session the API refuses to renew ends.
  Future<http.Response> post(String path, Map<String, Object> body) async {
    final response = await _postWithAccessToken(path, body);
    if (response.statusCode != 401) {
      return response;
    }
    await _renew();
    return isOpen ? _postWithAccessToken(path, body) : response;
  }

  Future<http.Response> _postWithAccessToken(String path, Map<String, Object> body) =>
      http.post(apiUri(path), headers: {...jsonHeaders, 'Authorization': 'Bearer $_accessToken'}, body: jsonEncode(body));

  Future<void> _renew() async {
    try {
      final response = await http.post(apiUri('/auth/refresh'), headers: jsonHeaders, body: jsonEncode({'refreshToken': _refreshToken}));
      if (response.statusCode == 200) {
        await _keep(response);
      } else if (response.statusCode == 401) {
        await _end('signIn.sessionExpired');
      }
    } on Exception catch (error) {
      debugPrint('Session not renewed: $error');
    }
  }

  Future<void> _keep(http.Response response) async {
    _apply(jsonDecode(response.body) as Map<String, dynamic>);
    await _storage.write(key: _storageKey, value: response.body);
    notifyListeners();
  }

  Future<void> _end(String notice) async {
    _apply({});
    _notice = notice;
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }

  void _apply(Map<String, dynamic> session) {
    _accessToken = session['accessToken'] as String? ?? '';
    _refreshToken = session['refreshToken'] as String? ?? '';
    _mustChangePassword = session['mustChangePassword'] as bool? ?? false;
  }
}
