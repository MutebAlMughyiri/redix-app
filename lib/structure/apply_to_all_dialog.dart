import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final navigator = Navigator.of(context);
    return AlertDialog(
      title: Text(words.columnsApplyQuestion),
      content: Text(words.columnsApplyExplain, key: explainKey),
      actions: [
        TextButton(key: templateOnlyKey, onPressed: () => navigator.pop(false), child: Text(words.columnsTemplateOnly)),
        FilledButton(key: applyKey, onPressed: () => navigator.pop(true), child: Text(words.columnsApplyToAll)),
      ],
    );
  }
}
