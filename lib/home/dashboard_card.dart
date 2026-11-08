import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../reports/dashboard.dart';
import '../ui/api_object_body.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';

/// The project's figures at a glance (UC-049): what waits for approval, the surplus, the completion (UC-063), the reconciliation difference, and revenue and expenses, each opening to its categories and each category to its items.
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

  /// The card.
  static const cardKey = Key('dashboard.card');

  /// The bar of the completion.
  static const completionBarKey = Key('dashboard.completionBar');

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

/// Which tile shows its categories.
enum _Side { none, revenue, expenses }

class _DashboardCardState extends State<DashboardCard> {
  final _openCategories = <String>{};
  var _side = _Side.none;

  @override
  void initState() {
    super.initState();
    widget.dashboard.loadOnOpen();
  }

  Widget _tile(String label, double amount, Key key, _Side side) => Expanded(
    child: Card.filled(
      key: key.card,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: key.body,
        onTap: () => setState(() => _side = _side == side ? _Side.none : side),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, key: key.label, style: Theme.of(context).textTheme.bodySmall)),
                  Icon(_side == side ? Icons.expand_less : Icons.expand_more, key: key.icon, size: 18),
                ],
              ),
              Text(formatMoney(amount), key: key, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    ),
  );

  /// The categories of the side opened, with no heading over them: the tile tapped already names the side (Muteb, 8 Nov 2026).
  Widget _categories(List<CategoryTotal> categories, double total) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (final category in categories) _category(category, total)],
  );

  Widget _category(CategoryTotal category, double total) {
    final isOpen = _openCategories.contains(category.id);
    final opens = category.items.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: DashboardCard.categoryKey(category.id),
          onTap: opens ? () => setState(() => isOpen ? _openCategories.remove(category.id) : _openCategories.add(category.id)) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(category.isCapital ? Words.of(context).categoriesTableCapital : category.name, key: DashboardCard.categoryKey(category.id).title)),
                    Text(formatMoney(category.total), key: DashboardCard.categoryKey(category.id).trailing),
                    if (opens) Icon(isOpen ? Icons.expand_less : Icons.expand_more, key: DashboardCard.categoryKey(category.id).icon, size: 18),
                  ],
                ),
                LinearProgressIndicator(key: DashboardCard.categoryKey(category.id).bar, value: total <= 0 ? 0 : (category.total / total).clamp(0, 1)),
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
              title: Text(item.name, key: DashboardCard.itemKey(item.id).title),
              trailing: Text(formatMoney(item.total), key: DashboardCard.itemKey(item.id).trailing),
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
            key: DashboardCard.pendingKey.card,
            margin: EdgeInsets.zero,
            color: theme.colorScheme.tertiaryContainer,
            child: ListTile(
              key: DashboardCard.pendingKey,
              title: Text(words.dashboardPending.replaceFirst('{0}', '${figures.pendingCount}'), key: DashboardCard.pendingKey.title),
              subtitle: Text('${words.dashboardPendingHint} · ${formatMoney(figures.pendingAmount)}', key: DashboardCard.pendingKey.subtitle),
              trailing: Icon(Icons.chevron_right, key: DashboardCard.pendingKey.icon),
              onTap: widget.onApprovals,
            ),
          ),
        Text(words.dashboardSurplus, key: DashboardCard.surplusKey.label, style: theme.textTheme.bodySmall),
        Text(formatMoney(figures.surplus), key: DashboardCard.surplusKey, style: theme.textTheme.headlineMedium),
        Text('${words.dashboardCompletion}: ${formatPlain(figures.completionPercent)}%', key: DashboardCard.completionKey),
        LinearProgressIndicator(key: DashboardCard.completionBarKey, value: (figures.completionPercent / 100).clamp(0, 1)),
        if (figures.wasReconciled)
          ColoredBox(
            color: figures.reconciliationDifference == 0 ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: Text(words.dashboardDifference, key: DashboardCard.differenceKey.label)),
                  Text(formatMoney(figures.reconciliationDifference), key: DashboardCard.differenceKey, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ),
        Row(
          spacing: 8,
          children: [
            _tile(words.dashboardRevenue, figures.revenue, DashboardCard.revenueKey, _Side.revenue),
            _tile(words.dashboardExpenses, figures.expenses, DashboardCard.expensesKey, _Side.expenses),
          ],
        ),
        if (_side == _Side.revenue) _categories(figures.revenueSide, figures.revenue),
        if (_side == _Side.expenses) _categories(figures.categories, figures.expenses),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    key: DashboardCard.cardKey,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(12), child: ApiObjectBody(object: widget.dashboard, builder: _figures)),
  );
}
