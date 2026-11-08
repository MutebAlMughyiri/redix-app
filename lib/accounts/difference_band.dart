import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../ui/part_keys.dart';

/// The reconciliation difference as a band, red while it is not zero (BR-08): the one look the dashboard and Accounts both show (findings row 166).
class DifferenceBand extends StatelessWidget {
  /// The band saying [label] and [difference], its figure keyed [figureKey] and its label by that key's label part.
  const DifferenceBand({super.key, required this.label, required this.difference, required this.figureKey});

  /// What it is called.
  final String label;

  /// The accounts' total less the surplus.
  final double difference;

  /// The figure's key.
  final Key figureKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOff = difference != 0;
    final color = isOff ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSurface;
    return ColoredBox(
      color: isOff ? theme.colorScheme.errorContainer : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(child: Text(label, key: figureKey.label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
            Text(formatMoney(difference), key: figureKey, style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
