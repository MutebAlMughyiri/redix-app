import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import '../words/words.dart';

/// Asks whether a change to the default template reaches the items that already exist (BR-21). It closes with true to apply it, false to keep it to the template.
class ApplyToAllDialog extends StatelessWidget {
  /// The question.
  const ApplyToAllDialog({super.key});

  /// What the choice means.
  static const explainKey = Key('applyToAll.explain');

  /// The button that applies the change to all items.
  static const applyKey = Key('applyToAll.apply');

  /// The button that keeps the change to the template.
  static const templateOnlyKey = Key('applyToAll.templateOnly');

  /// The dialog.
  static const dialogKey = Key('applyToAll.dialog');

  /// Its question.
  static const titleKey = Key('applyToAll.title');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final navigator = Navigator.of(context);
    return AlertDialog(
      key: dialogKey,
      title: Text(words.columnsApplyQuestion, key: titleKey),
      content: Text(words.columnsApplyExplain, key: explainKey),
      actions: [
        TextButton(key: templateOnlyKey, onPressed: () => navigator.pop(false), child: Text(words.columnsTemplateOnly, key: templateOnlyKey.label)),
        FilledButton(key: applyKey, onPressed: () => navigator.pop(true), child: Text(words.columnsApplyToAll, key: applyKey.label)),
      ],
    );
  }
}
