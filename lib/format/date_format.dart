/// A date as the app shows it, in both languages: Gregorian dd.MM.yyyy (NFR-04).
String formatDate(DateTime date) => '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';

/// A date as the API reads it: yyyy-MM-dd.
String apiDate(DateTime date) => date.toIso8601String().substring(0, 10);

/// The hour and minute of [time], as the app shows a time: 14:05.
String formatTime(DateTime time) => '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

String _twoDigits(int number) => number.toString().padLeft(2, '0');
