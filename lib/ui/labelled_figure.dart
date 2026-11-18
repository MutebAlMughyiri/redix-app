// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import 'part_keys.dart';

/// A figure with its label above it, sharing a row with others: the one cell the contract card and the payment form both draw (findings row 166).
class LabelledFigure extends StatelessWidget {
  /// [figure] under [label], keyed [figureKey] and its label by that key's label part, in [color] when one is given.
  const LabelledFigure({super.key, required this.label, required this.figure, required this.figureKey, this.color});

  /// What it is.
  final String label;

  /// The figure, already written.
  final String figure;

  /// The figure's key.
  final Key figureKey;

  /// The figure's color; the theme's when none is given.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, key: figureKey.label, style: theme.textTheme.bodySmall),
          Text(figure, key: figureKey, style: theme.textTheme.titleSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
