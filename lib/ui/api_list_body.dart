import 'package:flutter/material.dart';

import '../api_list.dart';
import 'filter_line.dart';
import 'list_search.dart';
import 'load_failure.dart';
import 'part_keys.dart';
import 'row_stripe.dart';

/// The body of a screen that shows an [ApiList]: why it could not load with a way to try again, loading, empty, or its items, which are read again when pulled down. A
/// list that grows has a search line over it, with its filters folded under the line's arrow (redix-app #104).
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

  /// What the list is searched by, and the filters folded under its search line; none for a list that stays short.
  final ListSearch<T> search;

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


  /// The line that says the list could not be read.
  static const messageKey = Key('apiList.message');

  /// The button that reads the list again.
  static const retryKey = Key('apiList.retry');

  /// The line shown while the list keeps no items.
  static const emptyKey = Key('apiList.empty');

  /// The spinner shown while the list is first read.
  static const loadingKey = Key('apiList.loading');

  /// The search line over a list that grows.
  static const searchKey = Key('apiList.search');

  /// The arrow at the end of the search line, opening and folding its filters.
  static const filtersKey = Key('apiList.filters');

  @override
  State<ApiListBody<T>> createState() => _ApiListBodyState<T>();
}

class _ApiListBodyState<T> extends State<ApiListBody<T>> {
  var _typed = '';
  var _filtersOpen = false;

  /// Reads the list, and whatever the screen shows besides it, again.
  Future<void> _refresh() => Future.wait([widget.list.load(), widget.alsoRefresh()]);

  bool _keeps(T item) => widget.keeps(item) && (_typed.trim().isEmpty || widget.search.matches(item, _typed));

  Widget _state(BuildContext context) {
    final list = widget.list;
    if (list.message.isNotEmpty) {
      return Center(child: LoadFailure(message: list.message, onRetry: list.load));
    }
    final kept = list.all.where(_keeps).toList();
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
    return RefreshIndicator(onRefresh: _refresh, child: widget.listOf([for (final (index, item) in kept.indexed) RowStripe(index: index, child: widget.itemBuilder(item))]));
  }

  /// The arrow at the end of the search line: up while the filters show, a filled filter while they are folded and narrow the list, down otherwise.
  IconData get _filtersIcon => _filtersOpen ? Icons.arrow_drop_up : (widget.search.filtersInUse ? Icons.filter_alt : Icons.arrow_drop_down);

  @override
  Widget build(BuildContext context) {
    final items = ListNarrowed(isNarrowed: _typed.trim().isNotEmpty, child: ListenableBuilder(listenable: widget.list, builder: (context, _) => _state(context)));
    final search = widget.search;
    if (search.isNone) {
      return items;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(
            key: ApiListBody.searchKey,
            hintText: search.hint,
            autoFocus: search.autoFocus,
            leading: Icon(Icons.search, key: ApiListBody.searchKey.icon),
            trailing: [
              if (search.filters.isNotEmpty)
                IconButton(key: ApiListBody.filtersKey, icon: Icon(_filtersIcon, key: ApiListBody.filtersKey.icon), onPressed: () => setState(() => _filtersOpen = !_filtersOpen)),
            ],
            onChanged: (typed) {
              setState(() => _typed = typed);
              search.onTyped(typed);
            },
          ),
        ),
        if (_filtersOpen) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: FilterLine(members: search.filters)),
        Expanded(child: items),
      ],
    );
  }
}
