import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../projects/new_project_screen.dart';
import '../words/words.dart';
import 'session.dart';

/// The sign-in screen (UC-002, تسجيل الدخول): username and password. A refusal shows as one line that never says which field was wrong (AC-01.2).
class SignInScreen extends StatefulWidget {
  /// The screen, signing in to [session].
  const SignInScreen({super.key, required this.session});

  /// The session this screen opens.
  final Session session;

  /// The screen's route.
  static const path = '/sign-in';

  /// The app's logo, at the top of the screen.
  static const logoKey = Key('signIn.logo');

  /// The app's name, under the logo.
  static const titleKey = Key('signIn.title');

  /// The username field.
  static const usernameKey = Key('signIn.username');

  /// The password field.
  static const passwordKey = Key('signIn.password');

  /// The sign-in button.
  static const submitKey = Key('signIn.submit');

  /// The link to register a new project.
  static const registerKey = Key('signIn.register');

  /// The line that says why sign-in was refused, or why the last session ended.
  static const messageKey = Key('signIn.message');

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  late var _message = widget.session.notice;
  var _signingIn = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    final refusal = await widget.session.signIn(_username.text.trim(), _password.text);
    if (mounted) {
      setState(() {
        _signingIn = false;
        _message = refusal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/icon/icon.png', key: SignInScreen.logoKey, height: 72),
              ),
            ),
            const SizedBox(height: 16),
            Text(words.appTitle, key: SignInScreen.titleKey, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(words.signInHint, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),
            TextField(
              key: SignInScreen.usernameKey,
              controller: _username,
              decoration: InputDecoration(labelText: words.signInUsername, border: const OutlineInputBorder()),
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              key: SignInScreen.passwordKey,
              controller: _password,
              decoration: InputDecoration(labelText: words.signInPassword, border: const OutlineInputBorder()),
              autofillHints: const [AutofillHints.password],
              obscureText: true,
              onSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: SignInScreen.submitKey,
              onPressed: _signingIn ? null : _signIn,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(words.signInSubmit),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(words.text(_message), key: SignInScreen.messageKey, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            TextButton(key: SignInScreen.registerKey, onPressed: () => context.push(NewProjectScreen.registerPath), child: Text(words.signInRegisterProject)),
            const SizedBox(height: 16),
            Text(words.signInForgotPassword, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
