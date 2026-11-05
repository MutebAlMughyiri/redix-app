import 'package:flutter/material.dart';

import 'app_language.dart';
import 'words.dart';

/// The choice between Arabic and English (UC-004), the same on the sign-in screen and in My account, with the line that says why it could not switch.
class LanguageSwitch extends StatefulWidget {
  /// The switch that changes [language].
  const LanguageSwitch({super.key, required this.language});

  /// The Arabic choice.
  static const arabicKey = Key('language.arabic');

  /// The English choice.
  static const englishKey = Key('language.english');

  /// The line that says why the language could not be switched.
  static const messageKey = Key('language.message');

  /// The language choice it changes.
  final AppLanguage language;

  @override
  State<LanguageSwitch> createState() => _LanguageSwitchState();
}

class _LanguageSwitchState extends State<LanguageSwitch> {
  var _message = '';
  var _switching = false;

  Future<void> _choose(String language) async {
    setState(() => _switching = true);
    final refusal = await widget.language.choose(language);
    if (mounted) {
      setState(() {
        _switching = false;
        _message = refusal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'ar', label: Text(words.myAccountArabic, key: LanguageSwitch.arabicKey)),
            ButtonSegment(value: 'en', label: Text(words.myAccountEnglish, key: LanguageSwitch.englishKey)),
          ],
          selected: {Localizations.localeOf(context).languageCode},
          onSelectionChanged: _switching ? null : (selection) => _choose(selection.single),
        ),
        if (_message.isNotEmpty) Text(words.text(_message), key: LanguageSwitch.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}
