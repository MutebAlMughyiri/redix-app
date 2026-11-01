import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'word_getters.g.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5010');

class Words with WordGetters {
  Words(this._values);

  final Map<String, String> _values;

  static const languages = ['ar', 'en'];
  static const _keptKey = 'words';

  bool get isEmpty => _values.isEmpty;

  static Words of(BuildContext context) => Localizations.of<Words>(context, Words)!;

  @override
  String text(String key) => _values[key] ?? key;

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

class WordsDelegate extends LocalizationsDelegate<Words> {
  const WordsDelegate(this.attempt);

  final int attempt;

  @override
  bool isSupported(Locale locale) => Words.languages.contains(locale.languageCode);

  @override
  Future<Words> load(Locale locale) => Words.load(locale.languageCode);

  @override
  bool shouldReload(WordsDelegate old) => old.attempt != attempt;
}
