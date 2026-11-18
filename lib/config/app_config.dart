// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

/// The configurable values the API keeps (UC-070): how long a request waits for its answer, and later anything else made configurable. Read at start, before anyone
/// signs in, and kept for the next start. Until the first answer ever arrives the times are zero, and a request waits as long as the phone lets it.
class AppConfig {
  static const _keptKey = 'config';

  var _requestTimeout = Duration.zero;
  var _fileTimeout = Duration.zero;

  /// How long any request waits for its answer before the app says there is no connection.
  Duration get requestTimeout => _requestTimeout;

  /// How long a file sent or read waits: an invoice, a document, a report's file.
  Duration get fileTimeout => _fileTimeout;

  /// Takes the values kept from the last start.
  Future<void> restore() async {
    final kept = (await SharedPreferences.getInstance()).getString(_keptKey) ?? '';
    if (kept.isNotEmpty) {
      apply(jsonDecode(kept) as Map<String, dynamic>);
    }
  }

  /// Reads the values from the API and keeps them for the next start; without a network the kept ones stay.
  Future<void> refresh() async {
    try {
      final response = await timed(http.get(apiUri('/config')));
      if (response.statusCode == 200) {
        apply(jsonOf(response) as Map<String, dynamic>);
        await (await SharedPreferences.getInstance()).setString(_keptKey, utf8.decode(response.bodyBytes));
      }
    } on Exception catch (error) {
      debugPrint('Config not read: $error');
    }
  }

  /// Takes [values] as the API answers them, each by its key as text.
  @visibleForTesting
  void apply(Map<String, dynamic> values) {
    _requestTimeout = _secondsOf(values, 'requestTimeoutSeconds');
    _fileTimeout = _secondsOf(values, 'fileTimeoutSeconds');
  }

  static Duration _secondsOf(Map<String, dynamic> values, String key) => Duration(seconds: int.tryParse('${values[key] ?? ''}') ?? 0);
}

/// The app's one config, read at start.
final config = AppConfig();

/// The answer to [request], given up after the configured time (UC-070): a [file] sent or read waits [AppConfig.fileTimeout], any other request
/// [AppConfig.requestTimeout]. Giving up throws a [TimeoutException], an [Exception] every caller already answers as no connection.
Future<T> timed<T>(Future<T> request, {bool file = false}) {
  final limit = file ? config.fileTimeout : config.requestTimeout;
  return limit == Duration.zero ? request : request.timeout(limit);
}
