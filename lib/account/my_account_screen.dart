import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/change_password_screen.dart';
import '../auth/session.dart';
import '../ui/confirm_dialog.dart';
import '../words/app_language.dart';
import '../words/language_switch.dart';
import '../words/words.dart';

/// My account (حسابي): the user's own settings: the language (UC-004), signing in with fingerprint or face (UC-011), the way to change the password (UC-003), and signing out
/// (UC-062).
class MyAccountScreen extends StatefulWidget {
  /// The screen, switching [language] and signing out of [session].
  const MyAccountScreen({super.key, required this.language, required this.session});

  /// The language choice this screen changes.
  final AppLanguage language;

  /// The session this screen signs out of.
  final Session session;

  /// The screen's route.
  static const path = '/my-account';

  /// The Arabic choice.
  static const arabicKey = LanguageSwitch.arabicKey;

  /// The English choice.
  static const englishKey = LanguageSwitch.englishKey;

  /// The line that says why the language could not be switched.
  static const messageKey = LanguageSwitch.messageKey;

  /// The switch that turns fingerprint or face on and off for this phone.
  static const biometricsKey = Key('myAccount.biometrics');

  /// The line that says why fingerprint or face did not change.
  static const biometricsMessageKey = Key('myAccount.biometricsMessage');

  /// The way into the password change.
  static const changePasswordKey = Key('myAccount.changePassword');

  /// The row that signs out, after asking.
  static const signOutKey = Key('myAccount.signOut');

  /// What signing out means, in the question.
  static const signOutExplainKey = ConfirmDialog.explanationKey;

  /// The button that signs out, in the question.
  static const confirmSignOutKey = ConfirmDialog.confirmKey;

  /// The button that changes nothing, in the question.
  static const cancelSignOutKey = ConfirmDialog.cancelKey;

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  var _biometricsMessage = '';

  /// Nothing waits on the prompt, because a cancelled one may never answer: the switch can always be tapped again.
  Future<void> _setBiometrics(bool on) async {
    final refusal = await widget.session.setBiometrics(on: on, words: Words.of(context));
    if (mounted) {
      setState(() => _biometricsMessage = refusal);
    }
  }

  void _askToSignOut() {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.myAccountSignOutQuestion,
        explanation: words.myAccountSignOutExplain,
        confirmLabel: words.myAccountSignOut,
        onConfirm: widget.session.signOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.myAccountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(words.myAccountLanguage, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          LanguageSwitch(language: widget.language),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: widget.session,
            builder: (context, _) => SwitchListTile(
              key: MyAccountScreen.biometricsKey,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.fingerprint),
              title: Text(words.biometricsSignIn),
              subtitle: Text(words.biometricsHint),
              value: widget.session.usesBiometrics,
              onChanged: _setBiometrics,
            ),
          ),
          if (_biometricsMessage.isNotEmpty)
            Text(words.text(_biometricsMessage), key: MyAccountScreen.biometricsMessageKey, style: TextStyle(color: theme.colorScheme.error)),
          ListTile(
            key: MyAccountScreen.changePasswordKey,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: Text(words.myAccountChangePassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(ChangePasswordScreen.path),
          ),
          ListTile(
            key: MyAccountScreen.signOutKey,
            contentPadding: EdgeInsets.zero,
            iconColor: theme.colorScheme.error,
            textColor: theme.colorScheme.error,
            leading: const Icon(Icons.logout),
            title: Text(words.myAccountSignOut),
            onTap: _askToSignOut,
          ),
        ],
      ),
    );
  }
}
