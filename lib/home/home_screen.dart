import 'package:flutter/material.dart';

import '../words/words.dart';

/// The screen a signed-in user lands on: today the app's name and what it is for; projects join it with UC-010.
class HomeScreen extends StatelessWidget {
  /// The home screen.
  const HomeScreen({super.key});

  /// The screen's route.
  static const path = '/';

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
