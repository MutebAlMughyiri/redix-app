import 'package:flutter/material.dart';

import 'change_dialog.dart';

/// Asks for one name, for adding or renaming anything in a project; or for one number, such as the «رقم القيد» an entry is found by (redix-api #128), typed on the [keyboardType] it asks.
class NameDialog extends StatefulWidget {
  /// The dialog [title] with a field labelled [label], starting from [name] and typed on [keyboardType]. The [saveLabel] button calls [onSave] with what was typed.
  const NameDialog({super.key, required this.title, required this.label, required this.saveLabel, this.name = '', this.keyboardType = TextInputType.text, required this.onSave});

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

  /// Sends the name, answering an empty string once saved, otherwise the word key of the refusal.
  final Future<String> Function(String name) onSave;

  /// The name.
  static const nameKey = Key('name.name');

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
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
        key: NameDialog.nameKey,
        controller: _name,
        autofocus: true,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(labelText: widget.label),
      ),
    ],
  );
}
