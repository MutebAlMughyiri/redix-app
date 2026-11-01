import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'word_getters.g.dart';

/// The API's address. `10.0.2.2` is the developer's machine as the Android emulator sees it; another address is passed with `--dart-define=API_BASE_URL=...`.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5010');

/// The words of the language in use, fetched from the API. The app's code names a word by its key; [WordGetters] gives one typed getter per key.
class Words with WordGetters {
  /// Words with these values, keyed by word key.
  Words(this._values);

  final Map<String, String> _values;

  /// The languages the app supports, Arabic first so it is the fallback for any other phone language.
  static const languages = ['ar', 'en'];
  static const _keptKey = 'words';

  /// True when the phone has no words yet: a first start without a network.
  bool get isEmpty => _values.isEmpty;

  /// The words of the language the screen is shown in.
  static Words of(BuildContext context) => Localizations.of<Words>(context, Words)!;

  @override
  String text(String key) => _values[key] ?? key;

  /// The words of [language]. Kept words show at once and are refreshed in the background; another language is fetched first and replaces the kept one, since the phone keeps one language only. Empty when there is no network and nothing kept.
  static Future<Words> load(String language) async {
    final preferences = await SharedPreferences.getInstance();
    final kept = _kept(preferences);
    final fetch = _fetch(preferences, language, kept.language == language ? kept.etag : '');
    if (kept.language == language) {
      unawaited(fetch);
      return Words(kept.words);
    }
    await fetch;
    final fetched = _kept(preferences);
    return Words(fetched.language == language ? fetched.words : {});
  }

  static ({String language, String etag, Map<String, String> words}) _kept(SharedPreferences preferences) {
    final kept = jsonDecode(preferences.getString(_keptKey) ?? '{"language": "", "etag": "", "words": {}}') as Map<String, dynamic>;
    return (language: kept['language'] as String, etag: kept['etag'] as String, words: Map<String, String>.from(kept['words'] as Map));
  }

  static Future<void> _fetch(SharedPreferences preferences, String language, String etag) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/translations/$language'),
        headers: {if (etag.isNotEmpty) 'If-None-Match': etag},
      );
      if (response.statusCode == 200) {
        final kept = {'language': language, 'etag': response.headers['etag'] ?? '', 'words': jsonDecode(utf8.decode(response.bodyBytes))};
        await preferences.setString(_keptKey, jsonEncode(kept));
      }
    } on Exception catch (error) {
      debugPrint('Words for $language not fetched: $error');
    }
  }
}

/// Loads [Words] through Flutter's localization, so a change of language loads that language's words.
class WordsDelegate extends LocalizationsDelegate<Words> {
  /// A delegate for this [attempt]; a new attempt reloads the words, which is how the no-network screen retries.
  const WordsDelegate(this.attempt);

  /// Counts the retries; a different value makes Flutter load the words again.
  final int attempt;

  @override
  bool isSupported(Locale locale) => Words.languages.contains(locale.languageCode);

  @override
  Future<Words> load(Locale locale) => Words.load(locale.languageCode);

  @override
  bool shouldReload(WordsDelegate old) => old.attempt != attempt;
}
