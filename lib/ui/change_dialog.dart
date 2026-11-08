import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';
import 'app_color.dart';

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
  var _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final refusal = await widget.onSave();
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
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
            ...widget.children,
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                words.text(_message),
                key: ChangeDialog.messageKey,
                style: TextStyle(color: AppColor.refusal.of(context)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(key: ChangeDialog.cancelKey, onPressed: Navigator.of(context).pop, child: Text(words.commonCancel, key: ChangeDialog.cancelKey.label)),
        FilledButton(key: ChangeDialog.saveKey, onPressed: _saving ? null : _save, child: Text(widget.saveLabel, key: ChangeDialog.saveKey.label)),
      ],
    );
  }
}
