import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../ui/api_object_body.dart';
import '../words/words.dart';
import 'reconciliation.dart';

/// What the accounts should hold, what they really held, and the difference, red while it is not zero (BR-08).
class ReconciliationCard extends StatelessWidget {
  /// The card of [reconciliations].
  const ReconciliationCard({super.key, required this.reconciliations});

  /// The surplus.
  static const surplusKey = Key('reconciliation.surplus');

  /// The total of the actual balances.
  static const actualTotalKey = Key('reconciliation.actualTotal');

  /// The difference.
  static const differenceKey = Key('reconciliation.difference');

  /// What is owed to partners.
  static const owedKey = Key('reconciliation.owed');

  /// The line saying no check was done.
  static const neverKey = Key('reconciliation.never');

  /// What it shows.
  final Reconciliations reconciliations;

  Widget _line(BuildContext context, Key key, String label, double amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(formatMoney(amount), key: key, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );

  Widget _difference(BuildContext context, ReconciliationFigures figures) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final isOff = figures.difference != 0;
    final color = isOff ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        ColoredBox(
          color: isOff ? theme.colorScheme.errorContainer : theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: Text(words.reconciliationsDifference, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                Text(formatMoney(figures.difference), key: differenceKey, style: theme.textTheme.titleMedium?.copyWith(color: color)),
              ],
            ),
          ),
        ),
        if (isOff) Text(words.reconciliationsDifferenceExplain, style: theme.textTheme.bodySmall),
        Text('${words.reconciliationsLastUpdated}: ${formatDate(figures.at)}', style: theme.textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ApiObjectBody(
          object: reconciliations,
          builder: (figures) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _line(context, surplusKey, words.reconciliationsSurplus, figures.surplus),
              if (figures.owedToPartners != 0) _line(context, owedKey, words.reconciliationsOwed, figures.owedToPartners),
              if (figures.wasChecked) ...[
                _line(context, actualTotalKey, words.reconciliationsActualTotal, figures.actualTotal),
                _difference(context, figures),
              ] else
                Text(words.reconciliationsNever, key: neverKey),
            ],
          ),
        ),
      ),
    );
  }
}
