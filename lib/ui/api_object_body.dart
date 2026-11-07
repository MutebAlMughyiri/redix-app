import 'package:flutter/material.dart';

import '../api_object.dart';
import '../words/words.dart';
import 'api_list_body.dart';
import 'part_keys.dart';

/// What shows something the API owns: why it could not load with a way to try again, or what [builder] draws from it.
class ApiObjectBody<T> extends StatelessWidget {
  /// The body showing [object] through [builder].
  const ApiObjectBody({super.key, required this.object, required this.builder});

  /// What this shows.
  final ApiObject<T> object;

  /// Draws it.
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: object,
      builder: (context, _) {
        if (object.message.isEmpty) {
          return builder(object.value);
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(words.text(object.message), key: ApiListBody.messageKey, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton(key: ApiListBody.retryKey, onPressed: object.load, child: Text(words.commonRetry, key: ApiListBody.retryKey.label)),
            ],
          ),
        );
      },
    );
  }
}
