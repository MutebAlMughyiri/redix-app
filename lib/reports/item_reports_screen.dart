// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/api_object_body.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../ui/search_line.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'summary.dart';
import 'item_report_screen.dart';
import 'category_share.dart';
import '../ui/row_stripe.dart';

/// المصروفات or الإيرادات (FR-33), each its own screen from Project settings (Muteb, 9 and 12 Nov 2026): every category of its [side] with its total and its share of
/// the side, opening on its items with theirs, each opening its report. The home's card shows the same categories and opens none of them. The search line over them keeps a
/// category whose name, or an item's, holds what was typed, open on those items, or on all of them when its own name holds it (redix-app #104).
class ItemReportsScreen extends StatefulWidget {
  /// The items of [project] on its [side], named by its [summary]'s figures.
  const ItemReportsScreen({super.key, required this.project, required this.summary, required this.side});

  /// The screen's route.
  static const path = '/projects/:projectId/item-reports/:side';

  /// The route of the item reports of the project [projectId] on its [side].
  static String pathOf(String projectId, SummarySide side) => '/projects/$projectId/item-reports/${side.name}';

  /// The way into the report of the item [id].
  static Key itemKey(String id) => Key('itemReports.item.$id');

  /// The category [id], opening on its items.
  static Key categoryKey(String id) => Key('itemReports.category.$id');

  /// The project.
  final Project project;

  /// Its figures, which name its items.
  final Summary summary;

  /// What it shows: the expenses or the revenue.
  final SummarySide side;

  @override
  State<ItemReportsScreen> createState() => _ItemReportsScreenState();
}

class _ItemReportsScreenState extends State<ItemReportsScreen> {
  var _typed = '';

  /// Each category's tile: opened while a search narrows the categories, folded once it is cleared.
  final _tiles = <String, ExpansibleController>{};

  @override
  void initState() {
    super.initState();
    widget.summary.loadOnOpen();
  }

  @override
  void dispose() {
    for (final tile in _tiles.values) {
      tile.dispose();
    }
    super.dispose();
  }

  bool get _isNarrowed => _typed.trim().isNotEmpty;

  /// The tile of the category [id], open from the start while a search narrows the categories.
  ExpansibleController _tileOf(String id) => _tiles.putIfAbsent(id, () => _isNarrowed ? (ExpansibleController()..expand()) : ExpansibleController());

  /// Keeps what was typed, opening every category while it narrows them and folding them once it is cleared.
  void _search(String typed) {
    setState(() => _typed = typed);
    for (final tile in _tiles.values) {
      if (_isNarrowed) {
        tile.expand();
      } else {
        tile.collapse();
      }
    }
  }

  /// The tile of [category], with its share of [sideTotal], listing the items [shown]: those holding what was typed, or all of them when its own name holds it.
  Widget _category(CategoryTotal category, List<ItemTotal> shown, double sideTotal) => ExpansionTile(
    key: ItemReportsScreen.categoryKey(category.id),
    controller: _tileOf(category.id),
    title: CategoryShare(category: category, sideTotal: sideTotal, parts: ItemReportsScreen.categoryKey(category.id)),
    children: [
      for (final (index, item) in shown.indexed)
        RowStripe(
          index: index,
          child: ListTile(
            key: ItemReportsScreen.itemKey(item.id),
            title: Text(item.name, key: ItemReportsScreen.itemKey(item.id).title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatMoney(item.total), key: ItemReportsScreen.itemKey(item.id).trailing),
                Icon(Icons.chevron_right, key: ItemReportsScreen.itemKey(item.id).icon),
              ],
            ),
            onTap: () => context.push(ItemReportScreen.pathOf(widget.project.id, item.id), extra: widget.project),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final side = widget.side;
    final title = words.text(side.wordKey);
    return SearchScope(
      onTyped: _search,
      child: Scaffold(
        appBar: AppBar(title: ScreenTitle(title, subject: widget.project.name), actions: const [SearchIcons()]),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchLine(hint: words.commonSearchIn.fill([title])),
            Expanded(
              child: ApiObjectBody(
                object: widget.summary,
                builder: (figures) => RefreshIndicator(
                  onRefresh: widget.summary.load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: ApiListBody.physics,
                    children: [
                      for (final category in side.categoriesOf(figures))
                        if (ListSearch.groupOf(category.name, category.items, (item) => item.name, _typed) case (isShown: true, :final children))
                          _category(category, children, side.totalOf(figures)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
