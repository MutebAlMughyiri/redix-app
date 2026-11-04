import 'package:flutter/material.dart';

import '../api_list.dart';
import '../words/words.dart';

/// The body of a screen that shows an [ApiList]: why it could not load with a way to try again, loading, empty, or its items.
class ApiListBody<T> extends StatelessWidget {
  /// The body of a screen showing [list], with [itemBuilder] drawing each item and [emptyText] said while it has none.
  const ApiListBody({super.key, required this.list, required this.emptyText, required this.itemBuilder});

  /// The list this body shows.
  final ApiList<T> list;

  /// What to say while the list has no items.
  final String emptyText;

  /// Draws one item.
  final Widget Function(T item) itemBuilder;

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
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [for (final item in list.all) itemBuilder(item)]);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: list, builder: (context, _) => _state(context));
}
