import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../words/words.dart';

/// One permission as a tick: its name and what it allows. A tick with no [onChanged] cannot be changed.
class PermissionTick extends StatelessWidget {
  /// The tick of [permission], ticked when [value], calling [onChanged] with the new value.
  const PermissionTick({super.key, required this.permission, required this.value, required this.onChanged});

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
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        title: Text(words.text(permission.wordKey)),
        subtitle: Text(words.text(permission.hintKey)),
        onChanged: change == null ? null : (ticked) => change(ticked ?? false),
      ),
    );
  }
}
