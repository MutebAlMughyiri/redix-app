import 'package:flutter/material.dart';

import '../accounts/difference_band.dart';
import '../auth/permission.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../reports/summary.dart';
import '../ui/api_object_body.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import '../ui/app_color.dart';
import '../reports/category_share.dart';

/// The project's figures at a glance (UC-049): what waits for approval, the surplus, the completion (UC-063), the reconciliation difference, and the revenue and expenses
/// totals, each opening to its categories with their totals, رأس المال among them (redix-api #109). A category opens nothing: its items and their reports are on
/// الإيرادات والمصروفات, from the home's buttons (Muteb, 9 Nov 2026).
class SummaryCard extends StatefulWidget {
  /// The card of [summary] in [project], calling [onApprovals] for what waits.
  const SummaryCard({super.key, required this.project, required this.summary, required this.onApprovals});

  /// The line saying how many wait for approval.
  static const pendingKey = Key('summary.pending');

  /// The surplus.
  static const surplusKey = Key('summary.surplus');

  /// The revenue.
  static const revenueKey = Key('summary.revenue');

  /// The expenses.
  static const expensesKey = Key('summary.expenses');

  /// The category [id], under the side opened.
  static Key categoryKey(String id) => Key('summary.category.$id');

  /// The reconciliation difference.
  static const differenceKey = Key('summary.difference');

  /// The completion.
  static const completionKey = Key('summary.completion');

  /// The card.
  static const cardKey = Key('summary.card');

  /// The bar of the completion.
  static const completionBarKey = Key('summary.completionBar');

  /// The project.
  final Project project;

  /// Its figures.
  final Summary summary;

  /// Opens what waits for approval.
  final VoidCallback onApprovals;

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  /// The side whose categories show: one at most, none at first.
  var _opened = <SummarySide>{};

  @override
  void initState() {
    super.initState();
    widget.summary.loadOnOpen();
  }

  Widget _tile(String label, Key key, SummarySide side, SummaryFigures figures) => Expanded(
    child: Card.filled(
      key: key.card,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: key.body,
        onTap: () => setState(() => _opened = _opened.contains(side) ? {} : {side}),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, key: key.label, style: Theme.of(context).textTheme.bodySmall)),
                  Icon(_opened.contains(side) ? Icons.expand_less : Icons.expand_more, key: key.icon, size: 18),
                ],
              ),
              Text(formatMoney(side.totalOf(figures)), key: key, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    ),
  );

  /// The categories of the side opened, each with its total and its share of the side, with no heading over them: the tile tapped already names the side (Muteb, 8 Nov
  /// 2026). None opens: their items are on الإيرادات والمصروفات (Muteb, 9 Nov 2026).
  Widget _categories(SummarySide side, SummaryFigures figures) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final category in side.categoriesOf(figures))
        Padding(
          key: SummaryCard.categoryKey(category.id),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: CategoryShare(category: category, sideTotal: side.totalOf(figures), parts: SummaryCard.categoryKey(category.id)),
        ),
    ],
  );

  Widget _figures(SummaryFigures figures) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final project = widget.project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (figures.waiting.count > 0 && project.may(Permission.approveEntries))
          Card.filled(
            key: SummaryCard.pendingKey.card,
            margin: EdgeInsets.zero,
            color: AppColor.noticeSurface.of(context),
            child: ListTile(
              key: SummaryCard.pendingKey,
              title: Text(words.summaryPending.replaceFirst('{0}', '${figures.waiting.count}'), key: SummaryCard.pendingKey.title),
              subtitle: Text(
                [
                  words.summaryPendingHint,
                  if (figures.waiting.expensesCount > 0) '${words.reportsPendingExpenses} (${figures.waiting.expensesCount}): ${formatMoney(figures.waiting.expensesAmount)}',
                  if (figures.waiting.revenueCount > 0) '${words.reportsPendingRevenue} (${figures.waiting.revenueCount}): ${formatMoney(figures.waiting.revenueAmount)}',
                ].join('\n'),
                key: SummaryCard.pendingKey.subtitle,
              ),
              trailing: Icon(Icons.chevron_right, key: SummaryCard.pendingKey.icon),
              onTap: widget.onApprovals,
            ),
          ),
        Text(words.summarySurplus, key: SummaryCard.surplusKey.label, style: theme.textTheme.bodySmall),
        Text(formatMoney(figures.surplus), key: SummaryCard.surplusKey, style: theme.textTheme.headlineMedium),
        Text('${words.summaryCompletion}: ${formatPlain(figures.completionPercent)}%', key: SummaryCard.completionKey),
        LinearProgressIndicator(key: SummaryCard.completionBarKey, value: (figures.completionPercent / 100).clamp(0, 1)),
        if (figures.wasReconciled) DifferenceBand(label: words.summaryDifference, difference: figures.reconciliationDifference, figureKey: SummaryCard.differenceKey),
        Row(
          spacing: 8,
          children: [
            _tile(words.summaryRevenue, SummaryCard.revenueKey, SummarySide.revenue, figures),
            _tile(words.summaryExpenses, SummaryCard.expensesKey, SummarySide.expenses, figures),
          ],
        ),
        for (final side in _opened) _categories(side, figures),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    key: SummaryCard.cardKey,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(12), child: ApiObjectBody(object: widget.summary, builder: _figures)),
  );
}
