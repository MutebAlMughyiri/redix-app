/// A date as the app shows it, in both languages: Gregorian dd.MM.yyyy (NFR-04).
String formatDate(DateTime date) => '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';

String _twoDigits(int number) => number.toString().padLeft(2, '0');
