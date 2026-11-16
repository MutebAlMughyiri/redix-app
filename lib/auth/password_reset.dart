import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../config/app_config.dart';

/// Asks for a code to the email of the account [login] names, by its username or its email (redix-api #127, AC-02.6, D5), in [language], the phone's (AC-02.10). Returns an
/// empty string once asked, whatever the account, since the API answers the same then (R5, AC-02.7); otherwise the word key of why not: `auth.tooManyRequests`,
/// `auth.noConnection` or `auth.refused`.
Future<String> askResetCode(String login, String language) => _send('/auth/forgot-password', {'login': login}, language);

/// Resets the password of the account [login] names with the [code] its email carried and the [newPassword] (redix-api #127, AC-02.6): every session of the person ends
/// (AC-02.9). Returns an empty string once reset, otherwise the word key of why not: `auth.codeWrong`, `auth.weakPassword`, `auth.tooManyRequests`, `auth.noConnection` or
/// `auth.refused`.
Future<String> resetWithCode(String login, String code, String newPassword) =>
    _send('/auth/reset-with-code', {'login': login, 'code': code, 'newPassword': newPassword}, '');

Future<String> _send(String path, Map<String, String> body, String language) async {
  try {
    final response = await timed(http.post(apiUri(path), headers: {...jsonHeaders, if (language.isNotEmpty) 'Accept-Language': language}, body: jsonEncode(body)));
    if (response.statusCode < 300) {
      return '';
    }
    return refusalIn(response, 'auth');
  } on Exception catch (error) {
    debugPrint('$path not sent: $error');
    return 'auth.noConnection';
  }
}
