import 'package:flutter/material.dart';

import '../api_list.dart';
import 'list_search.dart';
import 'load_failure.dart';
import 'row_stripe.dart';
import 'search_line.dart';

/// The body of a screen that shows an [ApiList]: why it could not load with a way to try again, loading, empty, or its items, which are read again when pulled down. A
/// list that grows has the [SearchLine] over it (redix-app #104).
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

  @override
  State<ApiListBody<T>> createState() => _ApiListBodyState<T>();
}

class _ApiListBodyState<T> extends State<ApiListBody<T>> {
  var _typed = '';

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
        SearchLine(
          search: search,
          onTyped: (typed) {
            setState(() => _typed = typed);
            search.onTyped(typed);
          },
        ),
        Expanded(child: items),
      ],
    );
  }
}
