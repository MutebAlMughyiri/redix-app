import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/change_password_screen.dart';
import '../auth/session.dart';
import '../ui/confirm_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';

/// My account (حسابي): the user's own settings: signing in with fingerprint or face (UC-011), the way to change the password (UC-003), and signing out (UC-062). The language
/// is chosen in Settings (UC-004).
class MyAccountScreen extends StatefulWidget {
  /// The screen, signing out of [session].
  const MyAccountScreen({super.key, required this.session});

  /// The session this screen signs out of.
  final Session session;

  /// The screen's route.
  static const path = '/my-account';

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
      appBar: AppBar(title: Text(words.myAccountTitle, key: ScreenTitle.titleKey)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListenableBuilder(
            listenable: widget.session,
            builder: (context, _) => SwitchListTile(
              key: MyAccountScreen.biometricsKey,
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.fingerprint, key: MyAccountScreen.biometricsKey.icon),
              title: Text(words.biometricsSignIn, key: MyAccountScreen.biometricsKey.title),
              subtitle: Text(words.biometricsHint, key: MyAccountScreen.biometricsKey.subtitle),
              value: widget.session.usesBiometrics,
              onChanged: _setBiometrics,
            ),
          ),
          if (_biometricsMessage.isNotEmpty)
            Text(words.text(_biometricsMessage), key: MyAccountScreen.biometricsMessageKey, style: TextStyle(color: theme.colorScheme.error)),
          ListTile(
            key: MyAccountScreen.changePasswordKey,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline, key: MyAccountScreen.changePasswordKey.icon),
            title: Text(words.myAccountChangePassword, key: MyAccountScreen.changePasswordKey.title),
            trailing: Icon(Icons.chevron_right, key: MyAccountScreen.changePasswordKey.trailing),
            onTap: () => context.push(ChangePasswordScreen.path),
          ),
          ListTile(
            key: MyAccountScreen.signOutKey,
            contentPadding: EdgeInsets.zero,
            iconColor: theme.colorScheme.error,
            textColor: theme.colorScheme.error,
            leading: Icon(Icons.logout, key: MyAccountScreen.signOutKey.icon),
            title: Text(words.myAccountSignOut, key: MyAccountScreen.signOutKey.title),
            onTap: _askToSignOut,
          ),
        ],
      ),
    );
  }
}
