import 'package:flutter/material.dart';

import 'change_dialog.dart';

/// Asks for one field: a name, for adding or renaming anything in a project, or a number, such as the «رقم القيد» an entry is found by (redix-api #128), typed on the [keyboardType] it asks.
class OneFieldDialog extends StatefulWidget {
  /// The dialog [title] with a field labelled [label], starting from [name] and typed on [keyboardType]. The [saveLabel] button calls [onSave] with what was typed.
  const OneFieldDialog({super.key, required this.title, required this.label, required this.saveLabel, this.name = '', this.keyboardType = TextInputType.text, this.below = const [], required this.onSave});

  /// The dialog's title.
  final String title;

  /// The field's label.
  final String label;

  /// The word on the button that saves.
  final String saveLabel;

  /// The name it starts from; empty for something new.
  final String name;

  /// The keyboard the field opens: letters for a name, digits for a number.
  final TextInputType keyboardType;

  /// What the dialog asks under its field, such as the accounts a payment method pays from (redix-app #109); nothing for most.
  final List<Widget> below;

  /// Sends the name, answering an empty string once saved, otherwise the word key of the refusal.
  final Future<String> Function(String name) onSave;

  /// The one field: the name or the number typed.
  static const fieldKey = Key('oneField.field');

  @override
  State<OneFieldDialog> createState() => _OneFieldDialogState();
}

class _OneFieldDialogState extends State<OneFieldDialog> {
  late final _name = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeDialog(
    title: widget.title,
    saveLabel: widget.saveLabel,
    onSave: () => widget.onSave(_name.text),
    children: [
      TextField(
        key: OneFieldDialog.fieldKey,
        controller: _name,
        autofocus: true,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(labelText: widget.label),
      ),
      ...widget.below,
    ],
  );
}
