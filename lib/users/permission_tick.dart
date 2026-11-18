// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';

/// One permission as a tick: its name and what it allows. A tick with no [onChanged] cannot be changed.
class PermissionTick extends StatelessWidget {
  /// The tick of [permission], ticked when [value], calling [onChanged] with the new value.
  const PermissionTick({required Key super.key, required this.permission, required this.value, required this.onChanged});

  /// The permission.
  final Permission permission;

  /// Whether it is held.
  final bool value;

  /// Called with the new value; null where it cannot change.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final change = onChanged;
    return Card.outlined(
      key: key.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        key: key.body,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        title: Text(words.text(permission.wordKey), key: key.title),
        subtitle: Text(words.text(permission.hintKey), key: key.subtitle),
        onChanged: change == null ? null : (ticked) => change(ticked ?? false),
      ),
    );
  }
}
