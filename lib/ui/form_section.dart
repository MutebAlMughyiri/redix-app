import 'package:flutter/material.dart';

import 'part_keys.dart';

/// One section of a long form: its [children] on a card, evenly spaced.
class FormSection extends StatelessWidget {
  /// The section holding [children], keyed [key] so a test finds it by its key.
  const FormSection(this.children, {required Key super.key});

  /// What the section holds, from top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card.outlined(
    key: key.card,
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, child) in children.indexed) ...[if (index > 0) const SizedBox(height: 12), child],
        ],
      ),
    ),
  );
}
