import '../format/number_format.dart';

/// The letters a person may write either way, as `ArabicSpelling` on the API treats them: what a search needs when it has no network to ask.
const _sameLetters = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و', 'ئ': 'ي'};

/// Typed text as every search matches it (findings row 167): trimmed, in Western digits, in one spelling.
String searchable(String typed) => sameSpelling(typedForApi(typed));

/// What was typed as a list searched on the API is asked it: trimmed, in Western digits; the API reads Arabic spelling alike itself (redix-app #104).
String typedForApi(String typed) => westernDigits(typed.trim());

/// [text] with Arabic spelling variants made one, and its tashkeel gone.
String sameSpelling(String text) => text.replaceAll(RegExp('[\u064B-\u0652]'), '').split('').map((letter) => _sameLetters[letter] ?? letter).join().toLowerCase();
