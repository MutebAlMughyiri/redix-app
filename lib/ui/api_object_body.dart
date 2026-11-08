import 'package:flutter/material.dart';

import '../api_object.dart';
import 'load_failure.dart';

/// What shows something the API owns: why it could not load with a way to try again, or what [builder] draws from it.
class ApiObjectBody<T> extends StatelessWidget {
  /// The body showing [object] through [builder].
  const ApiObjectBody({super.key, required this.object, required this.builder});

  /// What this shows.
  final ApiObject<T> object;

  /// Draws it.
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: object,
    builder: (context, _) => object.message.isEmpty ? builder(object.value) : LoadFailure(message: object.message, onRetry: object.load),
  );
}
