// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../ui/part_keys.dart';
import 'summary.dart';

/// A category's name and total over a bar of its share of its side, the one way the home's card and الإيرادات والمصروفات draw a category (deep review, 9 Nov 2026).
class CategoryShare extends StatelessWidget {
  /// The [category] as a share of [sideTotal], its parts keyed after [parts].
  const CategoryShare({super.key, required this.category, required this.sideTotal, required this.parts});

  /// The category.
  final CategoryTotal category;

  /// The total of its side.
  final double sideTotal;

  /// The key its name, total and bar take their parts of.
  final Key parts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 4,
    children: [
      Row(
        children: [
          Expanded(child: Text(category.name, key: parts.title)),
          Text(formatMoney(category.total), key: parts.trailing),
        ],
      ),
      LinearProgressIndicator(key: parts.bar, value: category.shareOf(sideTotal)),
    ],
  );
}
