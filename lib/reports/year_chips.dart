// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/part_keys.dart';

/// A year chosen as chips, from this year back to [firstYear].
class YearChips extends StatelessWidget {
  /// The chips with [year] chosen, from [firstYear], answering [onChanged] with the year chosen.
  const YearChips({super.key, required this.year, required this.firstYear, required this.onChanged});

  /// The choice of [year].
  static Key yearKey(int year) => Key('year.$year');

  /// The year chosen.
  final int year;

  /// The earliest year offered.
  final int firstYear;

  /// Called with the year chosen.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (var shown = DateTime.now().year; shown >= firstYear; shown--)
        ChoiceChip(key: yearKey(shown), label: Text('$shown', key: yearKey(shown).label), selected: shown == year, onSelected: (_) => onChanged(shown)),
    ],
  );
}
