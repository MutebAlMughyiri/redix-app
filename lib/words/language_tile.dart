import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import 'app_language.dart';
import 'words.dart';

/// The language row of Settings (UC-004): it names the language the app is in, and opens a choice of every language, one radio button each. The sign-in screen keeps its
/// own switch (Muteb, 8 Nov 2026).
class LanguageTile extends StatelessWidget {
  /// The row that changes [language].
  const LanguageTile({super.key, required this.language});

  /// The row, and the choice's title.
  static const tileKey = Key('settings.language');

  /// The radio button of [language].
  static Key optionKey(String language) => Key('settings.language.$language');

  /// The language choice it changes.
  final AppLanguage language;

  Future<void> _choose(BuildContext context) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final current = Localizations.localeOf(context).languageCode;
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(words.myAccountLanguage, key: tileKey.label),
        children: [
          RadioGroup<String>(
            key: tileKey.body,
            groupValue: current,
            onChanged: (value) => Navigator.of(dialogContext).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final each in Words.languages)
                  RadioListTile<String>(key: optionKey(each), value: each, title: Text(words.languageName(each), key: optionKey(each).title)),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen == null || chosen == current) {
      return;
    }
    final refusal = await language.choose(chosen);
    if (refusal.isNotEmpty) {
      showMessage(messenger, words, refusal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListTile(
      key: tileKey,
      leading: Icon(Icons.language, key: tileKey.icon),
      title: Text(words.myAccountLanguage, key: tileKey.title),
      subtitle: Text(words.languageName(Localizations.localeOf(context).languageCode), key: tileKey.subtitle),
      onTap: () => _choose(context),
    );
  }
}
