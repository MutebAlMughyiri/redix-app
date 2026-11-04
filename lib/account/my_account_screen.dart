import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/change_password_screen.dart';
import '../auth/session.dart';
import '../ui/confirm_dialog.dart';
import '../words/app_language.dart';
import '../words/words.dart';

/// My account (حسابي): the user's own settings. Today the language (UC-004), the way to change the password (UC-003), and signing out
/// (UC-062); the default project and face ID join it with UC-010 and UC-011.
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
  static const arabicKey = Key('myAccount.arabic');

  /// The English choice.
  static const englishKey = Key('myAccount.english');

  /// The line that says why the language could not be switched.
  static const messageKey = Key('myAccount.message');

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
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'ar', label: Text(words.myAccountArabic, key: MyAccountScreen.arabicKey)),
              ButtonSegment(value: 'en', label: Text(words.myAccountEnglish, key: MyAccountScreen.englishKey)),
            ],
            selected: {Localizations.localeOf(context).languageCode},
            onSelectionChanged: _switching ? null : (selection) => _choose(selection.single),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(words.text(_message), key: MyAccountScreen.messageKey, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 32),
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
