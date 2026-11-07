import 'package:flutter/material.dart';

import 'part_keys.dart';

/// A field whose value is chosen elsewhere: it looks like a text field, shows what was chosen, and opens the choice when tapped.
class PickerField extends StatelessWidget {
  /// The field labelled [label], showing [value], calling [onTap] when tapped.
  const PickerField({required Key super.key, required this.label, required this.value, required this.onTap});

  /// What is being chosen.
  final String label;

  /// What was chosen; empty for nothing yet.
  final String value;

  /// Opens the choice.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: key.body,
    onTap: onTap,
    child: InputDecorator(
      isEmpty: value.isEmpty,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: Icon(Icons.arrow_drop_down, key: key.icon)),
      child: Text(value, key: key.label),
    ),
  );
}
