// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import 'part_keys.dart';
import 'swipe_to_remove.dart';

/// What a [TypedNames] holds: the names added, each with the number its row keeps when another is swiped off, and the one still being typed.
class NameList {
  /// The field the next name is typed in.
  final field = TextEditingController();

  final _rows = <(int, String)>[];
  var _next = 0;

  /// Every name, the one still in the field last when it holds one: what a form sends.
  List<String> get all => [for (final (_, name) in _rows) name, if (field.text.trim().isNotEmpty) field.text];

  /// Lets the field go.
  void dispose() => field.dispose();
}

/// Names typed one at a time under a heading, each added by its button and taken off by a swipe (redix-api #102): a new project's units, and its partners (redix-api #109).
class TypedNames extends StatelessWidget {
  /// The list of [names] under [heading], typed in a field labelled [label] and added by a button named [addLabel]; [headingKey], [fieldKey], [addKey] and
  /// [rowKey] key its parts.
  const TypedNames({
    super.key,
    required this.names,
    required this.heading,
    required this.label,
    required this.addLabel,
    required this.headingKey,
    required this.fieldKey,
    required this.addKey,
    required this.rowKey,
    required this.onChanged,
  });

  /// What it holds.
  final NameList names;

  /// The heading over the names.
  final String heading;

  /// The field's label.
  final String label;

  /// The add button's word.
  final String addLabel;

  /// The heading's key.
  final Key headingKey;

  /// The field's key.
  final Key fieldKey;

  /// The add button's key.
  final Key addKey;

  /// The key of the row added [number]th, from 0.
  final Key Function(int number) rowKey;

  /// Called once a name is added or taken off, so the form shows it.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(heading, key: headingKey, style: Theme.of(context).textTheme.titleSmall),
      for (final (number, name) in names._rows)
        SwipeToRemove(
          rowKey: rowKey(number),
          mayRemove: true,
          onRemove: () async {
            names._rows.removeWhere((row) => row.$1 == number);
            onChanged();
            return '';
          },
          child: ListTile(key: rowKey(number), contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16), title: Text(name, key: rowKey(number).title)),
        ),
      const SizedBox(height: 12),
      TextField(
        key: fieldKey,
        controller: names.field,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: ValueListenableBuilder(
            valueListenable: names.field,
            builder: (context, typed, _) => TextButton.icon(
              key: addKey,
              icon: Icon(Icons.add, key: addKey.icon),
              label: Text(addLabel, key: addKey.label),
              onPressed: typed.text.trim().isEmpty
                  ? null
                  : () {
                      names._rows.add((names._next++, typed.text));
                      names.field.clear();
                      onChanged();
                    },
            ),
          ),
        ),
      ),
    ],
  );
}
