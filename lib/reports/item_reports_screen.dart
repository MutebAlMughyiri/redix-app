import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/api_object_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'dashboard.dart';
import 'item_report_screen.dart';
import 'category_share.dart';

/// الإيرادات والمصروفات (FR-33), on its own from the home (Muteb, 9 Nov 2026): a choice between the revenue categories and the expense categories, like the language's, then
/// every category of that side with its total and its share of the side, opening on its items with theirs, each opening its report. The expenses show first. The home's
/// card shows the same categories and opens none of them.
class ItemReportsScreen extends StatefulWidget {
  /// The items of [project], named by its [dashboard]'s figures.
  const ItemReportsScreen({super.key, required this.project, required this.dashboard});

  /// The screen's route.
  static const path = '/projects/:projectId/item-reports';

  /// The route of the item reports of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/item-reports';

  /// The choice between revenue and expenses.
  static const sideKey = Key('itemReports.side');

  /// One side of the choice.
  static Key sideOptionKey(DashboardSide side) => Key('itemReports.side.${side.name}');

  /// The way into the report of the item [id].
  static Key itemKey(String id) => Key('itemReports.item.$id');

  /// The category [id], opening on its items.
  static Key categoryKey(String id) => Key('itemReports.category.$id');

  /// The project.
  final Project project;

  /// Its figures, which name its items.
  final Dashboard dashboard;

  @override
  State<ItemReportsScreen> createState() => _ItemReportsScreenState();
}

class _ItemReportsScreenState extends State<ItemReportsScreen> {
  var _side = DashboardSide.expenses;

  @override
  void initState() {
    super.initState();
    widget.dashboard.loadOnOpen();
  }


  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reportsRevenueAndExpenses, subject: project.name)),
      body: ApiObjectBody(
        object: widget.dashboard,
        builder: (figures) => RefreshIndicator(
          onRefresh: widget.dashboard.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: ApiListBody.physics,
            children: [
              SegmentedButton<DashboardSide>(
                key: ItemReportsScreen.sideKey,
                segments: [
                  ButtonSegment(value: DashboardSide.revenue, label: Text(words.dashboardRevenue, key: ItemReportsScreen.sideOptionKey(DashboardSide.revenue))),
                  ButtonSegment(value: DashboardSide.expenses, label: Text(words.dashboardExpenses, key: ItemReportsScreen.sideOptionKey(DashboardSide.expenses))),
                ],
                selected: {_side},
                onSelectionChanged: (selection) => setState(() => _side = selection.single),
              ),
              const SizedBox(height: 8),
              for (final category in _side.categoriesOf(figures))
                ExpansionTile(
                  key: ItemReportsScreen.categoryKey(category.id),
                  title: CategoryShare(category: category, sideTotal: _side.totalOf(figures), parts: ItemReportsScreen.categoryKey(category.id)),
                  children: [
                    for (final item in category.items)
                      ListTile(
                        key: ItemReportsScreen.itemKey(item.id),
                        title: Text(item.name, key: ItemReportsScreen.itemKey(item.id).title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatMoney(item.total), key: ItemReportsScreen.itemKey(item.id).trailing),
                            Icon(Icons.chevron_right, key: ItemReportsScreen.itemKey(item.id).icon),
                          ],
                        ),
                        onTap: () => context.push(ItemReportScreen.pathOf(project.id, item.id), extra: project),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
