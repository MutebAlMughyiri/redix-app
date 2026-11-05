import 'package:flutter/material.dart';

/// A field whose value is chosen elsewhere: it looks like a text field, shows what was chosen, and opens the choice when tapped.
class PickerField extends StatelessWidget {
  /// The field labelled [label], showing [value], calling [onTap] when tapped.
  const PickerField({super.key, required this.label, required this.value, required this.onTap});

  /// What is being chosen.
  final String label;

  /// What was chosen; empty for nothing yet.
  final String value;

  /// Opens the choice.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      isEmpty: value.isEmpty,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.arrow_drop_down)),
      child: Text(value),
    ),
  );
}
