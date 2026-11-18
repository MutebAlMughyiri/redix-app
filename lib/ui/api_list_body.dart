// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../api_list.dart';
import 'list_search.dart';
import 'load_failure.dart';
import 'row_stripe.dart';
import 'search_line.dart';
import 'search_scope.dart';

/// The body of a screen that shows an [ApiList]: why it could not load with a way to try again, loading, empty, or its items, which are read again when pulled down. A
/// list that grows has the [SearchLine] over it, shown and filled through its screen's [ScreenSearch] (redix-app #104).
class ApiListBody<T> extends StatefulWidget {
  /// The body of a screen showing [list], with [itemBuilder] drawing each item [keeps] and [emptyText] said while it keeps none. A screen whose rows are dragged gives
  /// [listOf]; one that shows more than its list gives [alsoRefresh], read again with it; one whose list grows gives its [search].
  const ApiListBody({
    super.key,
    required this.list,
    required this.emptyText,
    required this.itemBuilder,
    this.keeps = keepsAll,
    this.listOf = plainList,
    this.alsoRefresh = nothingMore,
    this.search = const ListSearch.none(),
    this.groupOf = noGroup,
    this.headingOf = noHeading,
  });

  /// The list this body shows.
  final ApiList<T> list;

  /// What to say while the list keeps no items.
  final String emptyText;

  /// Which items are shown, for a screen that filters its list.
  final bool Function(T item) keeps;

  /// Draws one item.
  final Widget Function(T item) itemBuilder;

  /// What scrolls the drawn items, with [physics].
  final Widget Function(List<Widget> items) listOf;

  /// What else the screen reads again when the list is pulled down.
  final Future<void> Function() alsoRefresh;

  /// What the list is searched by, and the filters under its search line; none for a list that stays short.
  final ListSearch<T> search;

  /// The group an item is listed under, for a list drawn in groups with [headingOf] over the first item of each that shows; empty for no group.
  final String Function(T item) groupOf;

  /// The heading over a group's items.
  final Widget Function(String group) headingOf;

  /// How every list scrolls: always, so a list shorter than the screen can still be pulled down.
  static const physics = AlwaysScrollableScrollPhysics();

  /// The space around the items.
  static const padding = EdgeInsets.fromLTRB(16, 8, 16, 16);

  /// Every item.
  static bool keepsAll(Object? item) => true;

  /// A list that only scrolls.
  static Widget plainList(List<Widget> items) => ListView(padding: padding, physics: physics, children: items);

  /// Nothing besides the list.
  static Future<void> nothingMore() async {}

  /// No group: a list not drawn in groups.
  static String noGroup(Object? item) => '';

  /// No heading.
  static Widget noHeading(String group) => const SizedBox.shrink();

  /// The line that says the list could not be read.
  static const messageKey = Key('apiList.message');

  /// The button that reads the list again.
  static const retryKey = Key('apiList.retry');

  /// The line shown while the list keeps no items.
  static const emptyKey = Key('apiList.empty');

  /// The spinner shown while the list is first read.
  static const loadingKey = Key('apiList.loading');

  /// What scrolls the rows, pulled down to read them again.
  static const rowsKey = Key('apiList.rows');

  @override
  State<ApiListBody<T>> createState() => _ApiListBodyState<T>();
}

class _ApiListBodyState<T> extends State<ApiListBody<T>> {
  /// Reads the list, and whatever the screen shows besides it, again.
  Future<void> _refresh() => Future.wait([widget.list.load(), widget.alsoRefresh()]);

  bool _keeps(T item, String typed) => widget.keeps(item) && (typed.trim().isEmpty || widget.search.matches(item, typed));

  Widget _state(BuildContext context, String typed) {
    final list = widget.list;
    if (list.message.isNotEmpty) {
      return Center(child: LoadFailure(message: list.message, onRetry: list.load));
    }
    final kept = [for (final item in list.all) if (_keeps(item, typed)) item];
    if (kept.isEmpty) {
      return Center(
        child: list.isLoading && list.all.isEmpty
            ? const CircularProgressIndicator(key: ApiListBody.loadingKey)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(widget.emptyText, key: ApiListBody.emptyKey, textAlign: TextAlign.center),
              ),
      );
    }
    return RefreshIndicator(key: ApiListBody.rowsKey, onRefresh: _refresh, child: widget.listOf([for (var index = 0; index < kept.length; index++) _row(kept, index)]));
  }

  /// The row of the [index]th item [kept], under its group's heading when it is the first of its group that shows.
  Widget _row(List<T> kept, int index) {
    final group = widget.groupOf(kept[index]);
    final row = widget.itemBuilder(kept[index]);
    final startsGroup = group.isNotEmpty && (index == 0 || widget.groupOf(kept[index - 1]) != group);
    return RowStripe(index: index, child: startsGroup ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [widget.headingOf(group), row]) : row);
  }

  Widget _items(String typed) =>
      ListNarrowed(isNarrowed: typed.trim().isNotEmpty, child: ListenableBuilder(listenable: widget.list, builder: (context, _) => _state(context, typed)));

  @override
  Widget build(BuildContext context) {
    final search = widget.search;
    if (search.isNone) {
      return _items('');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchLine(hint: search.hint, filters: search.filters, waits: search.searchesOnApi),
        Expanded(child: _items(ScreenSearch.of(context).typed)),
      ],
    );
  }
}
