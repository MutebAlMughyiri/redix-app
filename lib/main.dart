import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'words/words.dart';

/// Starts the app.
void main() => runApp(const RedixApp());

/// The app: its theme, its languages, and the screen it opens on.
class RedixApp extends StatefulWidget {
  /// The app.
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

/// The screen the app opens on: its name and what it is for.
class HomeScreen extends StatelessWidget {
  /// The home screen.
  const HomeScreen({super.key});

  /// The app's name.
  static const titleKey = Key('home.title');

  /// What the app is for.
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

/// Shown on a first start without a network, when the app has no words yet; it needs none, only an icon and a retry button.
class NoWordsScreen extends StatelessWidget {
  /// The screen, calling [onRetry] when the user retries.
  const NoWordsScreen({super.key, required this.onRetry});

  /// Loads the words again.
  final VoidCallback onRetry;

  /// The no-network icon.
  static const iconKey = Key('noWords.icon');

  /// The retry button.
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
