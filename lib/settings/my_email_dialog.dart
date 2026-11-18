// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'shared_settings_screen.dart';

/// Settings › «بريدي», its first step (redix-api #127, AC-10.4): the new address, to which a code is sent in the phone's language (AC-02.10); the email stays as it was until the
/// code is entered in the second step, `MyEmailCodeDialog`, which Settings opens once [onSent] is told.
class MyEmailDialog extends StatefulWidget {
  /// The dialog asking a code for [session]'s user, telling [onSent] the address it went to.
  const MyEmailDialog({super.key, required this.session, required this.onSent});

  /// The session whose user's email changes.
  final Session session;

  /// Told the new address once its code is sent.
  final void Function(String email) onSent;

  @override
  State<MyEmailDialog> createState() => _MyEmailDialogState();
}

class _MyEmailDialogState extends State<MyEmailDialog> {
  late final _email = TextEditingController(text: widget.session.email);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<String> _send() async {
    final email = _email.text.trim();
    final refusal = await widget.session.askEmailCode(email, Localizations.localeOf(context).languageCode);
    if (refusal.isEmpty) {
      widget.onSent(email);
    }
    return refusal;
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.settingsMyEmail,
      saveLabel: words.authSendCode,
      onSave: _send,
      children: [
        TextField(
          key: SharedSettingsScreen.myEmailFieldKey,
          controller: _email,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: words.usersEmail),
        ),
      ],
    );
  }
}
