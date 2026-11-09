import 'package:flutter/material.dart';

import 'app_language.dart';
import 'words.dart';
import '../ui/refusal_text.dart';

/// The choice between Arabic and English (UC-004), on the sign-in screen and in Settings, with the line that says why it could not switch.
class LanguageSwitch extends StatefulWidget {
  /// The switch that changes [language].
  const LanguageSwitch({super.key, required this.language});

  /// The Arabic choice.
  static const arabicKey = Key('language.arabic');

  /// The English choice.
  static const englishKey = Key('language.english');

  /// The line that says why the language could not be switched.
  static const messageKey = Key('language.message');

  /// The choice of the language.
  static const choiceKey = Key('language.choice');

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
          key: LanguageSwitch.choiceKey,
          segments: [
            ButtonSegment(value: 'ar', label: Text(words.languageName('ar'), key: LanguageSwitch.arabicKey)),
            ButtonSegment(value: 'en', label: Text(words.languageName('en'), key: LanguageSwitch.englishKey)),
          ],
          selected: {Localizations.localeOf(context).languageCode},
          onSelectionChanged: _switching ? null : (selection) => _choose(selection.single),
        ),
        if (_message.isNotEmpty) refusalText(context, words.text(_message), LanguageSwitch.messageKey),
      ],
    );
  }
}
