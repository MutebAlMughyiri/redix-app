import 'package:flutter/material.dart';

import '../words/words.dart';

/// The new password and its confirmation, as Change password and «نسيت كلمة المرور؟» both ask them (redix-api #113, #127): the new one with the password rules under it, then
/// the same again. The one pair of fields a new password is typed in.
class NewPasswordFields extends StatelessWidget {
  /// The new password typed in [newPassword], keyed [newKey], and again in [confirmation], keyed [confirmKey]; [onSubmitted] runs when the confirmation is submitted.
  const NewPasswordFields({super.key, required this.newKey, required this.newPassword, required this.confirmKey, required this.confirmation, required this.onSubmitted});

  /// The key of the new password's field.
  final Key newKey;

  /// What the new password's field holds.
  final TextEditingController newPassword;

  /// The key of the confirmation's field.
  final Key confirmKey;

  /// What the confirmation's field holds.
  final TextEditingController confirmation;

  /// What submitting the confirmation does: what the screen's button does.
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        TextField(
          key: newKey,
          controller: newPassword,
          obscureText: true,
          decoration: InputDecoration(labelText: words.changePasswordNew, helperText: words.commonPasswordRules, helperMaxLines: 2),
        ),
        TextField(
          key: confirmKey,
          controller: confirmation,
          obscureText: true,
          decoration: InputDecoration(labelText: words.changePasswordConfirm),
          onSubmitted: (_) => onSubmitted?.call(),
        ),
      ],
    );
  }
}
