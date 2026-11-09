import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../ui/api_object_body.dart';
import '../words/words.dart';
import 'reconciliation.dart';
import 'difference_band.dart';
import '../ui/amount_line.dart';

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

  /// The line saying no check was done.
  static const neverKey = Key('reconciliation.never');

  /// The card.
  static const cardKey = Key('reconciliation.card');

  /// The line explaining a difference.
  static const differenceExplainKey = Key('reconciliation.differenceExplain');

  /// When the check was last done.
  static const lastUpdatedKey = Key('reconciliation.lastUpdated');

  /// What it shows.
  final Reconciliations reconciliations;

  Widget _line(BuildContext context, Key key, String label, double amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: amountLine(key, label, amount, amountStyle: Theme.of(context).textTheme.titleSmall),
  );

  Widget _difference(BuildContext context, ReconciliationFigures figures) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        DifferenceBand(label: words.reconciliationsDifference, difference: figures.difference, figureKey: differenceKey),
        if (figures.difference != 0) Text(words.reconciliationsDifferenceExplain, key: differenceExplainKey, style: theme.textTheme.bodySmall),
        Text('${words.reconciliationsLastUpdated}: ${formatDate(figures.at)}', key: lastUpdatedKey, style: theme.textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Card.outlined(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ApiObjectBody(
          object: reconciliations,
          builder: (figures) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _line(context, surplusKey, words.reconciliationsSurplus, figures.surplus),
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
