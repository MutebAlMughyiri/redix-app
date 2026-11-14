import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import '../words/words.dart';
import 'year_chips.dart';

/// The first day of the quarter [date] falls in.
DateTime quarterStartOf(DateTime date) => DateTime(date.year, (date.month - 1) ~/ 3 * 3 + 1);

/// The first and the last day of the quarter [date] falls in (AC-32.2).
(DateTime, DateTime) quarterOf(DateTime date) {
  final start = quarterStartOf(date);
  return (start, DateTime(start.year, start.month + 3, 0));
}

/// A quarter chosen by its year and its number, each as chips, from the year [firstYear] to this one.
class QuarterPicker extends StatelessWidget {
  /// The picker showing [start], from [firstYear], answering [onChanged] with the first day of the quarter chosen.
  const QuarterPicker({super.key, required this.start, required this.firstYear, required this.onChanged});

  /// The choice of the quarter [number], 1 to 4.
  static Key quarterKey(int number) => Key('quarter.q$number');

  /// The first day of the quarter chosen.
  final DateTime start;

  /// The earliest year offered.
  final int firstYear;

  /// Called with the first day of the quarter chosen.
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final number = (start.month - 1) ~/ 3 + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        YearChips(year: start.year, firstYear: firstYear, onChanged: (year) => onChanged(DateTime(year, start.month))),
        Wrap(
          spacing: 8,
          children: [
            for (var quarter = 1; quarter <= 4; quarter++)
              ChoiceChip(key: quarterKey(quarter), label: Text(words.text('vat.q$quarter'), key: quarterKey(quarter).label), selected: quarter == number, onSelected: (_) => onChanged(DateTime(start.year, (quarter - 1) * 3 + 1))),
          ],
        ),
      ],
    );
  }
}
