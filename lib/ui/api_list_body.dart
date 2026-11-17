import 'package:flutter/material.dart';

import '../api_list.dart';
import 'load_failure.dart';
import 'screen_message.dart';

/// The body of a screen that shows an [ApiList]: why it could not load with a way to try again, loading, empty, or its items, which are read again when pulled down.
class ApiListBody<T> extends StatelessWidget {
  /// The body of a screen showing [list], with [itemBuilder] drawing each item [keeps] and [emptyText] said while it keeps none. A screen whose rows are dragged gives
  /// [listOf]; one that shows more than its list gives [alsoRefresh], read again with it.
  const ApiListBody({super.key, required this.list, required this.emptyText, required this.itemBuilder, this.keeps = keepsAll, this.listOf = plainList, this.alsoRefresh = nothingMore});

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

  /// Reads the list, and whatever the screen shows besides it, again.
  Future<void> refresh() => Future.wait([list.load(), alsoRefresh()]);

  /// The line that says the list could not be read.
  static const messageKey = Key('apiList.message');

  /// The button that reads the list again.
  static const retryKey = Key('apiList.retry');

  /// The line shown while the list keeps no items.
  static const emptyKey = Key('apiList.empty');

  /// The spinner shown while the list is first read.
  static const loadingKey = Key('apiList.loading');

  Widget _state(BuildContext context) {
    if (list.message.isNotEmpty) {
      return LoadFailure(message: list.message, onRetry: list.load);
    }
    final kept = list.all.where(keeps).toList();
    if (kept.isEmpty) {
      return list.isLoading && list.all.isEmpty ? const Center(child: CircularProgressIndicator(key: loadingKey)) : ScreenMessage(emptyText, textKey: emptyKey);
    }
    return RefreshIndicator(onRefresh: refresh, child: listOf([for (final item in kept) itemBuilder(item)]));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: list, builder: (context, _) => _state(context));
}
