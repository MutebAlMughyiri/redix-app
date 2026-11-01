import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'auth/session.dart';
import 'auth/sign_in_screen.dart';
import 'home/home_screen.dart';
import 'words/no_words_screen.dart';
import 'words/words.dart';

/// Starts the app with the session kept from an earlier sign-in, if any.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  await session.restore();
  runApp(RedixApp(session: session));
}

/// The app: its theme, its languages, and its screens. Without a session every screen leads to sign-in.
class RedixApp extends StatefulWidget {
  /// The app, signed in through [session].
  const RedixApp({super.key, required this.session});

  /// The signed-in session the screens depend on.
  final Session session;

  @override
  State<RedixApp> createState() => _RedixAppState();
}

class _RedixAppState extends State<RedixApp> {
  var _wordsAttempt = 0;

  late final _router = GoRouter(
    refreshListenable: widget.session,
    redirect: (context, state) => _redirect(state.matchedLocation),
    routes: [
      GoRoute(path: HomeScreen.path, builder: (context, state) => const HomeScreen()),
      GoRoute(path: SignInScreen.path, builder: (context, state) => SignInScreen(session: widget.session)),
    ],
  );

  String? _redirect(String location) {
    final onSignIn = location == SignInScreen.path;
    if (!widget.session.isOpen && !onSignIn) {
      return SignInScreen.path;
    }
    if (widget.session.isOpen && onSignIn) {
      return HomeScreen.path;
    }
    return null;
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      onGenerateTitle: (context) => Words.of(context).appTitle,
      localizationsDelegates: [
        WordsDelegate(_wordsAttempt),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [for (final language in Words.languages) Locale(language)],
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0E6B68), fontFamily: 'IBMPlexSansArabic'),
      builder: (context, child) => Words.of(context).isEmpty
          ? NoWordsScreen(onRetry: () => setState(() => _wordsAttempt++))
          : child ?? const SizedBox.shrink(),
    );
  }
}
