import 'dart:convert';

import 'package:http/http.dart' as http;

/// The API's address, from the environment's config file: `--dart-define-from-file=config/local.json` on the developer's machine,
/// `config/production.json` for a release. Empty when the app was built without one.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// The host a shared entry's link names (redix-app #83), from the environment's config file like [apiBaseUrl]: the go-live domain in `config/production.json`; `redix.test`
/// until then, which Android hands to REDIX without looking it up. The Android manifest is given the same value by the build.
const linkHost = String.fromEnvironment('LINK_HOST', defaultValue: 'redix.test');

/// The address of an API [path], such as `/auth/sign-in`.
Uri apiUri(String path) => Uri.parse('$apiBaseUrl$path');

/// The headers of a request that sends JSON.
const jsonHeaders = {'Content-Type': 'application/json'};

/// The JSON [response] carries, read as UTF-8 so Arabic arrives unbroken.
dynamic jsonOf(http.Response response) => jsonDecode(utf8.decode(response.bodyBytes));

/// The JSON object [response] carries; empty when its body is empty or holds something else.
Map<String, dynamic> answerOf(http.Response response) {
  final answer = response.body.isEmpty ? null : jsonOf(response);
  return answer is Map<String, dynamic> ? answer : const {};
}

/// The word key, under [prefix], of the refusal [answer] names: `prefix.code`, or `prefix.refused` when it names no code.
String refusalOf(Map<String, dynamic> answer, String prefix) => '$prefix.${answer['code'] as String? ?? 'refused'}';
