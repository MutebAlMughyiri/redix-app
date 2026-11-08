import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/api_object_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'dashboard.dart';
import 'item_report_screen.dart';

/// تقرير بند (FR-33), on its own from the home (Muteb, 9 Nov 2026): every category with its items, each opening its report.
class ItemReportsScreen extends StatefulWidget {
  /// The items of [project], named by its [dashboard]'s figures.
  const ItemReportsScreen({super.key, required this.project, required this.dashboard});

  /// The screen's route.
  static const path = '/projects/:projectId/item-reports';

  /// The route of the item reports of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/item-reports';

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
      appBar: AppBar(title: ScreenTitle(words.reportsItem, subject: project.name)),
      body: ApiObjectBody(
        object: widget.dashboard,
        builder: (figures) => RefreshIndicator(
          onRefresh: widget.dashboard.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: ApiListBody.physics,
            children: [
              for (final category in figures.categories)
                ExpansionTile(
                  key: ItemReportsScreen.categoryKey(category.id),
                  title: Text(category.name, key: ItemReportsScreen.categoryKey(category.id).title),
                  children: [
                    for (final item in category.items)
                      ListTile(
                        key: ItemReportsScreen.itemKey(item.id),
                        title: Text(item.name, key: ItemReportsScreen.itemKey(item.id).title),
                        trailing: Icon(Icons.chevron_right, key: ItemReportsScreen.itemKey(item.id).icon),
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
