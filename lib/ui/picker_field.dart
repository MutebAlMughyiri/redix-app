// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import 'part_keys.dart';

/// A field whose value is chosen elsewhere: it looks like a text field, shows what was chosen, and opens the choice when tapped.
class PickerField extends StatelessWidget {
  /// The field labelled [label], showing [value], calling [onTap] when tapped, with [icon] at its end.
  const PickerField({required Key super.key, required this.label, required this.value, required this.onTap, this.icon = Icons.arrow_drop_down});

  /// What is being chosen.
  final String label;

  /// What was chosen; empty for nothing yet.
  final String value;

  /// Opens the choice.
  final VoidCallback onTap;

  /// What the choice is opened with: an arrow unless the field says otherwise.
  final IconData icon;

  @override
  Widget build(BuildContext context) => InkWell(
    key: key.body,
    onTap: onTap,
    child: InputDecorator(
      isEmpty: value.isEmpty,
      decoration: InputDecoration(labelText: label, suffixIcon: Icon(icon, key: key.icon)),
      child: Text(value, key: key.label),
    ),
  );
}
