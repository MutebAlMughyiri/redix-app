import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../offline/folder_store.dart';
import '../offline/local_store.dart';
import '../words/words.dart';
import 'biometrics.dart';
import 'permission.dart';
import '../config/app_config.dart';

/// The signed-in session (UC-002): the tokens the API issued, kept only in the Keychain or Keystore (NFR-09), and the one way to call the API as the user.
class Session extends ChangeNotifier {
  /// A session kept in the device's secure storage, the Keychain or Keystore, opened through [_biometrics] on a phone that uses them, with what it reads kept in [store].
  Session([this._storage = const FlutterSecureStorage(), this._biometrics = const Biometrics(), this.store = const FolderStore()]);

  /// What this phone keeps of what it read, and of what waits to be sent.
  final LocalStore store;

  /// The tries at the fingerprint or face before only the password works (AC-35.2).
  static const maxUnlockAttempts = 3;

  final FlutterSecureStorage _storage;
  final Biometrics _biometrics;
  static const _storageKey = 'session';
  static const _copies = 'copies';

  var _accessToken = '';
  var _refreshToken = '';
  var _userId = '';
  var _renewal = Future<void>.value();
  var _sending = Future<void>.value();
  var _mustChangePassword = false;
  var _permissions = <String>{};
  var _defaultProjectId = '';
  var _usesBiometrics = false;
  var _unlockAttempts = 0;
  var _notice = '';

  /// True from sign-in until the session ends.
  bool get isOpen => _refreshToken.isNotEmpty;

  /// The token sent with each request to the API; renewed with the refresh token.
  String get accessToken => _accessToken;

  /// True while the password is a temporary one that must be changed before anything else (UC-003).
  bool get mustChangePassword => _mustChangePassword;

  /// Whether the user holds [permission] everywhere; what they hold in a project comes with the project.
  bool may(Permission permission) => _permissions.contains(permission.name);

  /// The project sign-in opens directly, skipping the list (AC-37.1); empty when none, or when they can no longer read it (AC-37.2).
  String get defaultProjectId => _defaultProjectId;

  /// True when opening the app on this phone asks for a fingerprint or face (UC-011).
  bool get usesBiometrics => _usesBiometrics;

  /// True while the kept session waits for the fingerprint or face: 3 tries, then only the password works (AC-35.2).
  bool get canUnlock => _usesBiometrics && !isOpen && _unlockAttempts < maxUnlockAttempts;

  /// Makes [projectId] the default project, which sign-in opens directly. Returns an empty string once made, otherwise the word key of the refusal.
  Future<String> setDefaultProject(String projectId) => _changeDefault('/projects/$projectId/default', {});

  /// Clears the default project. Returns an empty string once made, otherwise the word key of the refusal.
  Future<String> removeDefaultProject() => _changeDefault('/projects/default/remove', {});

  Future<String> _changeDefault(String path, Map<String, Object> body) async {
    try {
      final response = await post(path, body);
      if (response.statusCode >= 300) {
        return 'projects.refused';
      }
      await _renew();
      return '';
    } on Exception catch (error) {
      debugPrint('Default project not changed: $error');
      return 'projects.noConnection';
    }
  }

  /// The word key of why the last session ended, for the sign-in screen; empty when there is nothing to say.
  String get notice => _notice;

  /// Reads the session kept from an earlier sign-in, then renews it in the background. A session the API refuses ends, with a notice;
  /// without a network the kept session stays open, so the app works offline (FR-16). On a phone that uses biometrics it waits for [unlock].
  Future<void> restore() async {
    final kept = await _kept();
    _usesBiometrics = kept['usesBiometrics'] as bool? ?? false;
    if (!_usesBiometrics) {
      _open(kept);
    }
    notifyListeners();
  }

  /// Asks for the fingerprint or face, and opens the kept session on a pass (AC-35.1). The try counts before the prompt opens, because a cancelled prompt may never answer.
  Future<bool> unlock(Words words) async {
    _unlockAttempts++;
    notifyListeners();
    final passed = await _biometrics.passes(words);
    if (passed) {
      _open(await _kept());
      notifyListeners();
    }
    return passed;
  }

  /// Turns fingerprint or face on or off for this phone. Turning on asks for it first. Returns an empty string once changed, otherwise the word key of why not.
  Future<String> setBiometrics({required bool on, required Words words}) async {
    if (on && !await _biometrics.turnOn(words)) {
      return 'biometrics.notAvailable';
    }
    try {
      final response = await post('/auth/biometrics', {'on': on});
      if (response.statusCode != 200) {
        return 'biometrics.notChanged';
      }
      await _keep(response);
      return '';
    } on Exception catch (error) {
      debugPrint('Biometrics not changed: $error');
      return 'biometrics.notChanged';
    }
  }

  Future<Map<String, dynamic>> _kept() async => jsonDecode(await _storage.read(key: _storageKey) ?? '{}') as Map<String, dynamic>;

  void _open(Map<String, dynamic> session) {
    _apply(session);
    if (isOpen) {
      unawaited(_renew());
    }
  }

  /// Signs in with [username] and [password] (FR-01). Returns an empty string once the session is open, otherwise the word key of the
  /// refusal: `signIn.invalidCredentials`, `signIn.accountLocked` or `signIn.noConnection`.
  Future<String> signIn(String username, String password) async {
    try {
      final response = await timed(http.post(apiUri('/auth/sign-in'), headers: jsonHeaders, body: jsonEncode({'username': username, 'password': password})));
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

  /// Signs out of this phone (UC-062). The phone forgets its tokens whatever the server answers, so leaving always works; the server closes
  /// the session now, or after 12 hours unused when it cannot be reached.
  Future<void> signOut() async {
    try {
      await post('/auth/sign-out', {});
    } on Exception catch (error) {
      debugPrint('Sign-out not sent: $error');
    }
    await _end('');
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

  /// Who is signed in; empty when nobody is.
  String get userId => _userId;

  /// Reads the API [path] as the signed-in user, renewing an expired access token like [post]. A list read is kept, and without a network the kept copy answers (FR-16).
  Future<http.Response> get(String path) async {
    try {
      final response = await read(path);
      if (response.statusCode == 200 && (response.headers['content-type'] ?? 'application/json').contains('json')) {
        await keepCopy(path, utf8.decode(response.bodyBytes));
      }
      return response;
    } on Exception {
      final copy = await copyOf(path);
      if (copy.isEmpty) {
        rethrow;
      }
      return http.Response.bytes(utf8.encode(copy), 200);
    }
  }

  /// Reads the API [path] and keeps nothing, waiting for a [file] as long as a file may take (UC-070). It waits for what was sent before it, so its answer already holds those changes.
  Future<http.Response> read(String path, {bool file = false}) async {
    await _sending;
    return _send(() => timed(http.get(apiUri(path), headers: _authorized), file: file));
  }

  /// Keeps [text] as what the API [path] answers, until sign-out.
  Future<void> keepCopy(String path, String text) => store.write(_copies, path, text);

  /// What the API [path] answered when last read; empty when it was not.
  Future<String> copyOf(String path) => store.read(_copies, path);

  /// Sends [body] as JSON to the API [path] as the signed-in user. An expired access token is renewed once and the request sent again;
  /// a session the API refuses to renew ends.
  Future<http.Response> post(String path, Map<String, Object> body) =>
      _remember(_send(() => timed(http.post(apiUri(path), headers: {...jsonHeaders, ..._authorized}, body: jsonEncode(body)))));

  /// Sends the file [bytes], named [fileName], with the form [fields] beside it, to the API [path] as the signed-in user, renewing an expired access token like [post].
  Future<http.Response> postFile(String path, String fileName, List<int> bytes, {Map<String, String> fields = const {}}) => _remember(_send(() async {
    final request = http.MultipartRequest('POST', apiUri(path))
      ..headers.addAll(_authorized)
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final client = http.Client();
    try {
      return await timed(client.send(request).then(http.Response.fromStream), file: true);
    } finally {
      client.close();
    }
  }));

  /// Keeps [sent] until it is answered, whatever the answer, for [get] to wait on.
  Future<http.Response> _remember(Future<http.Response> sent) {
    _sending = Future.wait<void>([_sending, sent.then<void>((_) {}, onError: (Object _) {})]);
    return sent;
  }

  Map<String, String> get _authorized => {'Authorization': 'Bearer $_accessToken'};

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final response = await request();
    if (response.statusCode != 401) {
      return response;
    }
    await _renew();
    return isOpen ? request() : response;
  }

  /// One renewal after another, each with the token the last one left: the API replaces the refresh token at every renewal, so a second sent at once would end the session.
  Future<void> _renew() => _renewal = _renewal.then((_) => _renewOnce());

  Future<void> _renewOnce() async {
    if (!isOpen) {
      return;
    }
    try {
      final response = await timed(http.post(apiUri('/auth/refresh'), headers: jsonHeaders, body: jsonEncode({'refreshToken': _refreshToken})));
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
    await store.clear(_copies);
    notifyListeners();
  }

  void _apply(Map<String, dynamic> session) {
    _accessToken = session['accessToken'] as String? ?? '';
    _refreshToken = session['refreshToken'] as String? ?? '';
    _userId = session['userId'] as String? ?? '';
    _mustChangePassword = session['mustChangePassword'] as bool? ?? false;
    _permissions = {...(session['permissions'] as List<dynamic>? ?? []).cast<String>()};
    _defaultProjectId = session['defaultProjectId'] as String? ?? '';
    _usesBiometrics = session['usesBiometrics'] as bool? ?? false;
  }
}
