import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'session.dart';

/// The change-password screen (UC-003, غيّر كلمة المرور): the current password and the new one twice. While the password is temporary the
/// router keeps the user here, so the change cannot be skipped (AC-02.1).
class ChangePasswordScreen extends StatefulWidget {
  /// The screen, changing the password of [session]'s user.
  const ChangePasswordScreen({super.key, required this.session});

  /// The session whose user's password this screen changes.
  final Session session;

  /// The screen's route.
  static const path = '/change-password';

  /// The current password field.
  static const currentKey = Key('changePassword.current');

  /// The new password field.
  static const newKey = Key('changePassword.new');

  /// The field that repeats the new password.
  static const confirmKey = Key('changePassword.confirm');

  /// The save button.
  static const submitKey = Key('changePassword.submit');

  /// The line that says why the change was refused.
  static const messageKey = Key('changePassword.message');

  /// The title.
  static const titleKey = Key('changePassword.title');

  /// What to do.
  static const hintKey = Key('changePassword.hint');

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  var _message = '';
  var _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text != _confirm.text) {
      setState(() => _message = 'changePassword.mismatch');
      return;
    }
    setState(() => _saving = true);
    final refusal = await widget.session.changePassword(_current.text, _new.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
    if (refusal.isEmpty) {
      context.go(HomeScreen.landingOf(widget.session));
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    InputDecoration field(String label) => InputDecoration(labelText: label);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(words.changePasswordTitle, key: ChangePasswordScreen.titleKey, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(words.changePasswordHint, key: ChangePasswordScreen.hintKey, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),
            TextField(key: ChangePasswordScreen.currentKey, controller: _current, decoration: field(words.changePasswordCurrent), obscureText: true),
            const SizedBox(height: 16),
            TextField(key: ChangePasswordScreen.newKey, controller: _new, decoration: field(words.changePasswordNew), obscureText: true),
            const SizedBox(height: 16),
            TextField(
              key: ChangePasswordScreen.confirmKey,
              controller: _confirm,
              decoration: field(words.changePasswordConfirm),
              obscureText: true,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: ChangePasswordScreen.submitKey,
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(words.changePasswordSubmit, key: ChangePasswordScreen.submitKey.label),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(words.text(_message), key: ChangePasswordScreen.messageKey, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
