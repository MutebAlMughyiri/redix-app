import 'package:flutter/material.dart';

/// Two fields of a form, side by side and of equal width.
class TwoFields extends StatelessWidget {
  /// The row holding [first] and [second].
  const TwoFields(this.first, this.second, {super.key});

  /// The field that comes first in the reading direction.
  final Widget first;

  /// The field after it.
  final Widget second;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: first),
      const SizedBox(width: 8),
      Expanded(child: second),
    ],
  );
}
