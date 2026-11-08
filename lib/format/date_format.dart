/// A date as the app shows it, in both languages: Gregorian dd.MM.yyyy (NFR-04).
String formatDate(DateTime date) => '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';

/// A date as the API reads it: yyyy-MM-dd.
String apiDate(DateTime date) => date.toIso8601String().substring(0, 10);

String _twoDigits(int number) => number.toString().padLeft(2, '0');
