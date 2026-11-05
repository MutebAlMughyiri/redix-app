/// The letters a person may write either way, as `ArabicSpelling` on the API treats them: what a search needs when it has no network to ask.
const _sameLetters = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و', 'ئ': 'ي'};

/// [text] with Arabic spelling variants made one, and its tashkeel gone.
String sameSpelling(String text) => text.replaceAll(RegExp('[\u064B-\u0652]'), '').split('').map((letter) => _sameLetters[letter] ?? letter).join().toLowerCase();
