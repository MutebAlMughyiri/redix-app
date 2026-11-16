import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../format/number_format.dart';
import '../config/app_config.dart';
import '../format/date_format.dart';

/// Registers a project from the sign-in page, with its [units], its [partners] (redix-api #109) and [description], no session, and a new login as its manager (UC-066). Returns an
/// empty string once sent, otherwise the word key of the refusal.
Future<String> registerProject(
  String name,
  DateTime startDate,
  List<String> units,
  List<String> partners,
  String description, {
  required String displayName,
  required String username,
  required String mobile,
  required String password,
}) async {
  try {
    final response = await timed(http.post(
      apiUri('/projects/register'),
      headers: jsonHeaders,
      body: jsonEncode({
        'name': name,
        'startDate': apiDate(startDate),
        'units': units,
        'partners': partners,
        'description': description,
        'displayName': displayName,
        'username': username,
        'mobile': westernDigits(mobile),
        'password': password,
      }),
    ));
    if (response.statusCode < 300) {
      return '';
    }
    return refusalIn(response, 'register', tooMany: 'register.tooManyTries');
  } on Exception catch (error) {
    debugPrint('Project not registered: $error');
    return 'register.noConnection';
  }
}
