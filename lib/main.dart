import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'words/words.dart';

void main() => runApp(const RedixApp());

class RedixApp extends StatefulWidget {
  const RedixApp({super.key});

  @override
  State<RedixApp> createState() => _RedixAppState();
}

class _RedixAppState extends State<RedixApp> {
  var _wordsAttempt = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => Words.of(context).appTitle,
      localizationsDelegates: [
        WordsDelegate(_wordsAttempt),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [for (final language in Words.languages) Locale(language)],
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0E6B68), fontFamily: 'IBMPlexSansArabic'),
      home: const HomeScreen(),
      builder: (context, child) => Words.of(context).isEmpty
          ? NoWordsScreen(onRetry: () => setState(() => _wordsAttempt++))
          : child ?? const SizedBox.shrink(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const titleKey = Key('home.title');
  static const subtitleKey = Key('home.subtitle');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(words.appTitle, key: titleKey, style: textTheme.headlineLarge),
            Text(words.appSubtitle, key: subtitleKey, style: textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class NoWordsScreen extends StatelessWidget {
  const NoWordsScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static const iconKey = Key('noWords.icon');
  static const retryKey = Key('noWords.retry');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, key: iconKey, size: 48),
            IconButton(key: retryKey, icon: const Icon(Icons.refresh), onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
