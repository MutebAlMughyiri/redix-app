import 'package:flutter/material.dart';

import '../ui/app_color.dart';
import '../ui/amount_line.dart';

/// The reconciliation difference as a band, red while it is not zero (BR-08): the one look the summary and Accounts both show (findings row 166).
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
    final color = isOff ? AppColor.onRefusalSurface.of(context) : AppColor.text.of(context);
    return ColoredBox(
      color: isOff ? AppColor.refusalSurface.of(context) : AppColor.mutedSurface.of(context),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: amountLine(figureKey, label, difference, labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold), amountStyle: theme.textTheme.titleMedium?.copyWith(color: color)),
      ),
    );
  }
}
