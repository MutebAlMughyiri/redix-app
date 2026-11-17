import 'package:flutter/material.dart';

import 'part_keys.dart';

/// One component of loose parts, the fields of a form or a list's filter, in its one border, evenly spaced (redix-app #96). Its parts carry no border of their own, and a
/// list's rows, which have theirs, never sit inside it.
class Section extends StatelessWidget {
  /// The section holding [children], keyed [key] so a test finds it by its key.
  const Section(this.children, {required Key super.key});

  /// What the section holds, from top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card.outlined(
    key: key.card,
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
