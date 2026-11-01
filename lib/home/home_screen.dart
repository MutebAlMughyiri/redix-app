import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account/my_account_screen.dart';
import '../words/words.dart';

/// The screen a signed-in user lands on: today the app's name and what it is for, and the way into My account; projects join it with UC-010.
class HomeScreen extends StatelessWidget {
  /// The home screen.
  const HomeScreen({super.key});

  /// The screen's route.
  static const path = '/';

  /// The app's name.
  static const titleKey = Key('home.title');

  /// What the app is for.
  static const subtitleKey = Key('home.subtitle');

  /// The button that opens My account.
  static const myAccountKey = Key('home.myAccount');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: myAccountKey,
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: words.myAccountTitle,
            onPressed: () => context.push(MyAccountScreen.path),
          ),
        ],
      ),
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
