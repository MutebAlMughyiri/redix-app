import 'package:flutter/material.dart';

import 'part_keys.dart';

/// A choice among a few, drawn as chips under what is being chosen.
class LabelledChips<T> extends StatelessWidget {
  /// The chips of [choices] under [label], each with the key [keyOf] gives and the name [nameOf] gives, marked by [isChosen] and answering [onChosen].
  const LabelledChips({required Key super.key, required this.label, required this.choices, required this.keyOf, required this.nameOf, required this.isChosen, required this.onChosen});

  /// What is being chosen.
  final String label;

  /// What can be chosen.
  final Iterable<T> choices;

  /// The key of a choice's chip.
  final Key Function(T) keyOf;

  /// The name a choice shows.
  final String Function(T) nameOf;

  /// Whether a choice is the one chosen.
  final bool Function(T) isChosen;

  /// Called with the choice tapped.
  final ValueChanged<T> onChosen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, key: key.label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        children: [
          for (final choice in choices) ChoiceChip(key: keyOf(choice), label: Text(nameOf(choice), key: keyOf(choice).label), selected: isChosen(choice), onSelected: (_) => onChosen(choice)),
        ],
      ),
    ],
  );
}
