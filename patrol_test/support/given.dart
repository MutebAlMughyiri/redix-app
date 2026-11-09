import 'dart:convert';

import 'package:http/http.dart' as http;

/// Someone a case signs in as, and the project they are in.
class Person {
  /// [username] signs in with [password], and [id] is in the project [projectId].
  const Person({required this.id, required this.username, required this.password, required this.projectId});

  /// Their user id.
  final String id;

  /// What they sign in with.
  final String username;

  /// Their password as it stands.
  final String password;

  /// The one project they are in.
  final String projectId;
}

/// What a case finds already in place, made through the real API so that only what the case is about goes through the screens.
class Given {
  Given._();

  static const _base = String.fromEnvironment('API_BASE_URL');
  static const _adminUsername = String.fromEnvironment('TEST_USERNAME');
  static const _adminTemporaryPassword = String.fromEnvironment('TEST_PASSWORD');
  static const _adminPassword = String.fromEnvironment('TEST_NEW_PASSWORD');
  static var _made = 0;

  /// A short text no other case of this run has, since usernames must not repeat.
  static String unique() => '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${_made++}';

  /// The manager of a new approved project, signing in with a password of their own.
  static Future<Person> manager() async {
    final mark = unique();
    final username = 'manager-$mark';
    final password = 'Chosen-$mark';
    final project = await _post('/projects/register', {
      'name': 'Project $mark',
      'startDate': DateTime.now().toIso8601String().substring(0, 10),
      'units': <String>[],
      'displayName': 'Manager $mark',
      'username': username,
      'mobile': '',
      'password': password,
    });
    final projectId = project['id'] as String;
    await _post('/projects/$projectId/approve', {}, await _adminToken());
    return Person(id: '', username: username, password: password, projectId: projectId);
  }

  /// A new person in the project of [manager], who can only see it. With [temporary] they still hold the password they must change.
  static Future<Person> member(Person manager, {bool temporary = false}) async {
    final mark = unique();
    final username = 'member-$mark';
    final temporaryPassword = 'Temporary-$mark';
    final user = await _post('/projects/${manager.projectId}/users', {'displayName': 'Member $mark', 'username': username, 'mobile': '', 'temporaryPassword': temporaryPassword}, await _tokenOf(manager));
    final id = user['id'] as String;
    if (temporary) {
      return Person(id: id, username: username, password: temporaryPassword, projectId: manager.projectId);
    }
    final password = 'Chosen-$mark';
    final session = await _signedIn(username, temporaryPassword);
    await _post('/auth/change-password', {'currentPassword': temporaryPassword, 'newPassword': password}, session['accessToken'] as String);
    return Person(id: id, username: username, password: password, projectId: manager.projectId);
  }

  /// [manager] disables [person].
  static Future<void> disabled(Person person, {required Person by}) async {
    await _post('/users/${person.id}/disable', {}, await _tokenOf(by));
  }

  /// Whether the API lets [username] sign in with [password] now.
  static Future<bool> canSignIn(String username, String password) async => (await _signIn(username, password)).statusCode == 200;

  static Future<String> _tokenOf(Person person) async => (await _signedIn(person.username, person.password))['accessToken'] as String;

  /// The admin's token. The API seeds the admin with a temporary password, so the first case of a run changes it.
  static Future<String> _adminToken() async {
    if (!await canSignIn(_adminUsername, _adminPassword)) {
      final first = await _signedIn(_adminUsername, _adminTemporaryPassword);
      await _post('/auth/change-password', {'currentPassword': _adminTemporaryPassword, 'newPassword': _adminPassword}, first['accessToken'] as String);
    }
    return (await _signedIn(_adminUsername, _adminPassword))['accessToken'] as String;
  }

  static Future<http.Response> _signIn(String username, String password) =>
      http.post(Uri.parse('$_base/auth/sign-in'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'password': password}));

  static Future<Map<String, dynamic>> _signedIn(String username, String password) async {
    final answer = await _signIn(username, password);
    return _bodyOf('sign-in of $username', answer);
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, Object> body, [String token = '']) async {
    final answer = await http.post(Uri.parse('$_base$path'), headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'}, body: jsonEncode(body));
    return _bodyOf('POST $path', answer);
  }

  static Map<String, dynamic> _bodyOf(String what, http.Response answer) {
    if (answer.statusCode >= 300) {
      throw StateError('$what answered ${answer.statusCode}: ${answer.body}');
    }
    return answer.body.isEmpty ? {} : jsonDecode(utf8.decode(answer.bodyBytes)) as Map<String, dynamic>;
  }
}
