// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

/// A date as the app shows it, in both languages: Gregorian dd.MM.yyyy (NFR-04).
String formatDate(DateTime date) => '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';

/// A date as the API reads it: yyyy-MM-dd.
String apiDate(DateTime date) => date.toIso8601String().substring(0, 10);

/// The hour and minute of [time], as the app shows a time: 14:05.
String formatTime(DateTime time) => '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

String _twoDigits(int number) => number.toString().padLeft(2, '0');

/// A moment the API sends, which it marks UTC, as the phone's own time: when a history line, a file, a notification or a report happened.
DateTime momentOf(String sent) => DateTime.parse(sent).toLocal();

/// Whether [moment] is the API's "not happened", 1 January 1900 as it sends it, however the phone's own time moves it.
bool isNever(DateTime moment) => moment.year <= 1900;
