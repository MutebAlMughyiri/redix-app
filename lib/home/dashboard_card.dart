import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../reports/dashboard.dart';
import '../ui/api_object_body.dart';
import '../words/words.dart';

/// The project's figures at a glance (UC-049): what waits for approval, the surplus, revenue and expenses, the reconciliation difference, completion and cost (UC-063), and expenses by category, each opening to its items.
class DashboardCard extends StatefulWidget {
  /// The card of [dashboard] in [project], calling [onApprovals] for what waits and [onItem] for an item's report.
  const DashboardCard({super.key, required this.project, required this.dashboard, required this.onApprovals, required this.onItem});

  /// The line saying how many wait for approval.
  static const pendingKey = Key('dashboard.pending');

  /// The surplus.
  static const surplusKey = Key('dashboard.surplus');

  /// The revenue.
  static const revenueKey = Key('dashboard.revenue');

  /// The expenses.
  static const expensesKey = Key('dashboard.expenses');

  /// The reconciliation difference.
  static const differenceKey = Key('dashboard.difference');

  /// The completion.
  static const completionKey = Key('dashboard.completion');

  /// The category [id].
  static Key categoryKey(String id) => Key('dashboard.category.$id');

  /// The item [id] under its category.
  static Key itemKey(String id) => Key('dashboard.item.$id');

  /// The project.
  final Project project;

  /// Its figures.
  final Dashboard dashboard;

  /// Opens what waits for approval.
  final VoidCallback onApprovals;

  /// Opens an item's report.
  final void Function(ItemTotal item) onItem;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  final _openCategories = <String>{};

  @override
  void initState() {
    super.initState();
    widget.dashboard.loadOnOpen();
  }

  Widget _tile(String label, double amount, Key key) => Expanded(
    child: Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(formatMoney(amount), key: key, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    ),
  );

  Widget _category(CategoryTotal category, double expenses) {
    final isOpen = _openCategories.contains(category.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: DashboardCard.categoryKey(category.id),
          onTap: () => setState(() => isOpen ? _openCategories.remove(category.id) : _openCategories.add(category.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(category.name)),
                    Text(formatMoney(category.total)),
                    Icon(isOpen ? Icons.expand_less : Icons.expand_more, size: 18),
                  ],
                ),
                LinearProgressIndicator(value: expenses <= 0 ? 0 : (category.total / expenses).clamp(0, 1)),
              ],
            ),
          ),
        ),
        if (isOpen)
          for (final item in category.items)
            ListTile(
              key: DashboardCard.itemKey(item.id),
              dense: true,
              contentPadding: const EdgeInsetsDirectional.only(start: 16),
              title: Text(item.name),
              trailing: Text(formatMoney(item.total)),
              onTap: () => widget.onItem(item),
            ),
      ],
    );
  }

  Widget _figures(DashboardFigures figures) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final project = widget.project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (figures.pendingCount > 0 && project.may(Permission.approveEntries))
          Card.filled(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.tertiaryContainer,
            child: ListTile(
              key: DashboardCard.pendingKey,
              title: Text(words.dashboardPending.replaceFirst('{0}', '${figures.pendingCount}')),
              subtitle: Text('${words.dashboardPendingHint} · ${formatMoney(figures.pendingAmount)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onApprovals,
            ),
          ),
        Text(words.dashboardSurplus, style: theme.textTheme.bodySmall),
        Text(formatMoney(figures.surplus), key: DashboardCard.surplusKey, style: theme.textTheme.headlineMedium),
        Text('${words.dashboardSurplusWithoutSales}: ${formatMoney(figures.surplusWithoutSales)}', style: theme.textTheme.bodySmall),
        Row(spacing: 8, children: [_tile(words.dashboardRevenue, figures.revenue, DashboardCard.revenueKey), _tile(words.dashboardExpenses, figures.expenses, DashboardCard.expensesKey)]),
        if (figures.wasReconciled)
          ColoredBox(
            color: figures.reconciliationDifference == 0 ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: Text(words.dashboardDifference)),
                  Text(formatMoney(figures.reconciliationDifference), key: DashboardCard.differenceKey, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ),
        Text('${words.dashboardCompletion}: ${formatPlain(figures.completionPercent)}% · ${words.dashboardCost}: ${formatMoney(figures.expenses)}', key: DashboardCard.completionKey),
        LinearProgressIndicator(value: (figures.completionPercent / 100).clamp(0, 1)),
        if (figures.categories.isNotEmpty) Text(words.dashboardByCategory, style: theme.textTheme.titleMedium),
        for (final category in figures.categories) _category(category, figures.expenses),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(12), child: ApiObjectBody(object: widget.dashboard, builder: _figures)),
  );
}
