import 'package:flutter/material.dart';

import '../api_list.dart';
import '../words/words.dart';

/// The body of a screen that shows an [ApiList]: why it could not load with a way to try again, loading, empty, or its items, which are read again when pulled down.
class ApiListBody<T> extends StatelessWidget {
  /// The body of a screen showing [list], with [itemBuilder] drawing each item and [emptyText] said while it has none. A screen whose rows are dragged gives [listOf];
  /// one that shows more than its list gives [alsoRefresh], read again with it.
  const ApiListBody({super.key, required this.list, required this.emptyText, required this.itemBuilder, this.listOf = plainList, this.alsoRefresh = nothingMore});

  /// The list this body shows.
  final ApiList<T> list;

  /// What to say while the list has no items.
  final String emptyText;

  /// Draws one item.
  final Widget Function(T item) itemBuilder;

  /// What scrolls the drawn items, with [physics].
  final Widget Function(List<Widget> items) listOf;

  /// What else the screen reads again when the list is pulled down.
  final Future<void> Function() alsoRefresh;

  /// How every list scrolls: always, so a list shorter than the screen can still be pulled down.
  static const physics = AlwaysScrollableScrollPhysics();

  /// The space around the items, leaving room for a floating button.
  static const padding = EdgeInsets.fromLTRB(16, 8, 16, 96);

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

  /// The line shown while the list has no items.
  static const emptyKey = Key('apiList.empty');

  Widget _state(BuildContext context) {
    final words = Words.of(context);
    if (list.message.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(words.text(list.message), key: messageKey, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(key: retryKey, onPressed: list.load, child: Text(words.commonRetry)),
            ],
          ),
        ),
      );
    }
    if (list.all.isEmpty) {
      return Center(
        child: list.isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(emptyText, key: emptyKey, textAlign: TextAlign.center),
              ),
      );
    }
    return RefreshIndicator(onRefresh: refresh, child: listOf([for (final item in list.all) itemBuilder(item)]));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: list, builder: (context, _) => _state(context));
}
