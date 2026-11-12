import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'user.dart';
import 'users.dart';
import 'users_screen.dart';

/// Sets a new temporary password for a user, typed by whoever manages them, who passes it on.
class ResetPasswordDialog extends StatefulWidget {
  /// The dialog resetting [user] through [users].
  const ResetPasswordDialog({super.key, required this.user, required this.users});

  /// The user to reset.
  final User user;

  /// The way to change them.
  final Users users;

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.usersResetPassword,
      saveLabel: words.usersResetPassword,
      onSave: () => widget.users.resetPassword(widget.user, _password.text),
      children: [
        Text(
          widget.user.displayName,
          key: UsersScreen.resetNameKey,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(words.usersResetExplain, key: UsersScreen.resetExplainKey),
        const SizedBox(height: 16),
        TextField(
          key: UsersScreen.resetPasswordFieldKey,
          controller: _password,
          autocorrect: false,
          decoration: InputDecoration(labelText: words.usersTemporaryPassword, helperText: words.commonPasswordRules, helperMaxLines: 2),
        ),
      ],
    );
  }
}
