import 'dart:convert';

import 'package:http/http.dart' as http;

/// The API's address, from the environment's config file: `--dart-define-from-file=config/dev.json` for automated runs, `config/qa.json` for
/// Muteb's own testing, `config/prod.json` for a release (redix-api #118). Empty when the app was built without one.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// The host a shared entry's link names (redix-app #83), from the environment's config file like [apiBaseUrl]: the go-live domain in `config/prod.json`; `redix.test`
/// until then, which Android hands to REDIX without looking it up. The Android manifest is given the same value by the build.
const linkHost = String.fromEnvironment('LINK_HOST', defaultValue: 'redix.test');

/// The address of an API [path], such as `/auth/sign-in`.
Uri apiUri(String path) => Uri.parse('$apiBaseUrl$path');

/// The headers of a request that sends JSON.
const jsonHeaders = {'Content-Type': 'application/json'};

/// The JSON [response] carries, read as UTF-8 so Arabic arrives unbroken.
dynamic jsonOf(http.Response response) => jsonDecode(utf8.decode(response.bodyBytes));

/// What [response] carries, made by [make]: the one way an answer becomes what the app holds. An answer in a shape this version does not read, as a copy an earlier
/// version kept on the phone may be, throws a [FormatException] as an answer that is not JSON does, so every reader treats it as nothing kept and the next read comes
/// from the API (redix-api #126); no reader keeps a way to read an old shape. A field of another type is a [TypeError], a name this version's enum does not hold an
/// [ArgumentError].
T madeFrom<T>(http.Response response, T Function(Object? json) make) {
  try {
    return make(jsonOf(response));
  } on TypeError catch (error) {
    throw FormatException('An answer in a shape this version does not read: $error');
  } on ArgumentError catch (error) {
    throw FormatException('An answer in a shape this version does not read: $error');
  }
}

/// The JSON object [response] carries; empty when its body is empty or holds something else.
Map<String, dynamic> answerOf(http.Response response) {
  final answer = response.body.isEmpty ? null : jsonOf(response);
  return answer is Map<String, dynamic> ? answer : const {};
}

/// The word key, under [prefix], of the refusal [answer] names: `prefix.code`, or `prefix.refused` when it names no code.
String refusalOf(Map<String, dynamic> answer, String prefix) => '$prefix.${answer['code'] as String? ?? 'refused'}';

/// The word key of why [response] was refused: asking too often, which a limited route answers with no code of its own, says [tooMany]; any other refusal what [refusalOf] says
/// under [prefix]. The one place a 429 is told apart.
String refusalIn(http.Response response, String prefix, {String tooMany = 'auth.tooManyRequests'}) => response.statusCode == 429 ? tooMany : refusalOf(answerOf(response), prefix);
