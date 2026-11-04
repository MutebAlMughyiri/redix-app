import 'dart:convert';

import 'package:http/http.dart' as http;

/// The API's address, from the environment's config file: `--dart-define-from-file=config/local.json` on the developer's machine,
/// `config/production.json` for a release. Empty when the app was built without one.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// The address of an API [path], such as `/auth/sign-in`.
Uri apiUri(String path) => Uri.parse('$apiBaseUrl$path');

/// The headers of a request that sends JSON.
const jsonHeaders = {'Content-Type': 'application/json'};

/// The JSON [response] carries, read as UTF-8 so Arabic arrives unbroken.
dynamic jsonOf(http.Response response) => jsonDecode(utf8.decode(response.bodyBytes));
