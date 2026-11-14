import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../ui/change_dialog.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'shared_settings_screen.dart';

/// Settings › «بريدي», its second step (redix-api #127, AC-10.4): the code sent to [email], which makes it the user's email once entered; until then the old one holds.
class MyEmailCodeDialog extends StatefulWidget {
  /// The dialog confirming [email] for [session]'s user.
  const MyEmailCodeDialog({super.key, required this.session, required this.email});

  /// The session whose user's email changes.
  final Session session;

  /// The new address the code went to.
  final String email;

  @override
  State<MyEmailCodeDialog> createState() => _MyEmailCodeDialogState();
}

class _MyEmailCodeDialogState extends State<MyEmailCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.settingsMyEmail,
      saveLabel: words.usersSave,
      onSave: () => widget.session.confirmEmail(_code.text.trim()),
      children: [
        Text(words.settingsEmailConfirm.fill([widget.email]), key: SharedSettingsScreen.myEmailSentToKey),
        const SizedBox(height: 16),
        TextField(
          key: SharedSettingsScreen.myEmailCodeKey,
          controller: _code,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: words.authCode),
        ),
      ],
    );
  }
}
