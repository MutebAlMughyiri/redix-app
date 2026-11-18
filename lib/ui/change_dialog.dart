// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';
import 'form_error.dart';
import 'act_once.dart';

/// A dialog that sends a change: it closes once saved, and a refusal stays in it with what was typed.
class ChangeDialog extends StatefulWidget {
  /// The dialog [title], holding [children]. The [saveLabel] button calls [onSave], which answers an empty string once saved, otherwise the word key of the refusal.
  const ChangeDialog({super.key, required this.title, required this.children, required this.saveLabel, required this.onSave});

  /// The dialog's title.
  final String title;

  /// What the dialog holds, such as its fields.
  final List<Widget> children;

  /// The word on the button that saves.
  final String saveLabel;

  /// Sends the change.
  final Future<String> Function() onSave;

  /// The button that saves.
  static const saveKey = Key('change.save');

  /// The line that says why the change was refused.
  static const messageKey = Key('change.message');

  /// The dialog.
  static const dialogKey = Key('change.dialog');

  /// Its title.
  static const titleKey = Key('change.title');

  /// The button that closes it unchanged.
  static const cancelKey = Key('change.cancel');

  @override
  State<ChangeDialog> createState() => _ChangeDialogState();
}

class _ChangeDialogState extends State<ChangeDialog> {
  var _message = '';

  Future<void> _save() async {
    final refusal = await widget.onSave();
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _message = refusal);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return AlertDialog(
      key: ChangeDialog.dialogKey,
      title: Text(widget.title, key: ChangeDialog.titleKey),
      content: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_message.isNotEmpty) FormError(text: words.text(_message), textKey: ChangeDialog.messageKey),
            ...widget.children,
          ],
        ),
      ),
      actions: [
        TextButton(key: ChangeDialog.cancelKey, onPressed: Navigator.of(context).pop, child: Text(words.commonCancel, key: ChangeDialog.cancelKey.label)),
        ActOnce(builder: (once) => FilledButton(key: ChangeDialog.saveKey, onPressed: once(_save), child: Text(widget.saveLabel, key: ChangeDialog.saveKey.label))),
      ],
    );
  }
}
