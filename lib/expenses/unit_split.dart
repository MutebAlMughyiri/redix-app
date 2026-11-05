import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../projects/project.dart';
import '../words/words.dart';

/// How an expense recorded against the shared unit is split between the project's own units (UC-060, FR-15): equally, or a percentage each, together 100. The API checks the parts; the app gathers them.
class UnitSplit {
  /// Whether the expense is split.
  var isSplit = false;

  /// Whether the units take equal parts; otherwise each takes the percentage typed for it in [percents].
  var isEqual = true;

  /// The percentage typed for each unit, by its id.
  final percents = <String, String>{};

  /// [count] equal parts of 100, to two decimals, the last taking what is left so that together they make 100; none for no units.
  static List<double> equalParts(int count) {
    final hundredths = 10000 ~/ math.max(count, 1);
    return [for (var i = 0; i < count; i++) (i == count - 1 ? 10000 - hundredths * (count - 1) : hundredths) / 100];
  }

  /// Each of [units] with its part; a unit with no number typed takes none.
  List<(Unit, double)> partsOf(List<Unit> units) {
    if (isEqual) {
      final parts = equalParts(units.length);
      return [for (var i = 0; i < units.length; i++) (units[i], parts[i])];
    }
    return [
      for (final unit in units)
        if (!parseNumber(percents[unit.id] ?? '').isNaN) (unit, parseNumber(percents[unit.id]!)),
    ];
  }

  /// What the API is sent for [units]: each unit's part; empty when it is not split.
  List<Map<String, Object>> toSend(List<Unit> units) => [
    if (isSplit)
      for (final (unit, percent) in partsOf(units)) {'unitId': unit.id, 'percent': percent},
  ];

  /// Takes the parts [held] by the entry being changed, as the API answers them: equal when they are what an equal split of [units] gives.
  void take(List<Unit> units, List<dynamic> held) {
    final parts = {for (final part in held.cast<Map<String, dynamic>>()) part['unitId'] as String: (part['percent'] as num).toDouble()};
    final equal = equalParts(units.length);
    isSplit = parts.isNotEmpty;
    isEqual = !isSplit || (parts.length == units.length && [for (var i = 0; i < units.length; i++) parts[units[i].id] == equal[i]].every((matches) => matches));
    percents
      ..clear()
      ..addAll(parts.map((unitId, percent) => MapEntry(unitId, formatPlain(percent))));
  }
}

/// The fields of a [UnitSplit] between [units]: the switch, equal or by percentage, and each unit's part with what they make together.
class UnitSplitFields extends StatelessWidget {
  /// The fields of [split] between [units], calling [onChanged] after each change.
  const UnitSplitFields({super.key, required this.split, required this.units, required this.onChanged});

  /// The switch that splits the expense.
  static const splitKey = Key('unitSplit.split');

  /// The choice of equal parts.
  static const equalKey = Key('unitSplit.equal');

  /// The choice of a percentage each.
  static const percentKey = Key('unitSplit.percent');

  /// What the parts make together.
  static const totalKey = Key('unitSplit.total');

  /// The part of the unit [id].
  static Key partKey(String id) => Key('unitSplit.part.$id');

  /// The split.
  final UnitSplit split;

  /// The project's own units.
  final List<Unit> units;

  /// Called after each change.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final parts = split.partsOf(units);
    final total = parts.fold(0.0, (sum, part) => sum + part.$2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SwitchListTile(
          key: splitKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.expensesSplit),
          value: split.isSplit,
          onChanged: (isSplit) {
            split.isSplit = isSplit;
            onChanged();
          },
        ),
        if (split.isSplit) ...[
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(words.expensesSplitEqual, key: equalKey)),
              ButtonSegment(value: false, label: Text(words.expensesSplitPercent, key: percentKey)),
            ],
            selected: {split.isEqual},
            onSelectionChanged: (selected) {
              split.isEqual = selected.single;
              onChanged();
            },
          ),
          for (final unit in units)
            split.isEqual
                ? Text('${unit.name}: ${formatPlain(parts.firstWhere((part) => part.$1.id == unit.id).$2)}%', key: partKey(unit.id))
                : TextFormField(
                    key: partKey(unit.id),
                    initialValue: split.percents[unit.id] ?? '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: unit.name, suffixText: '%', border: const OutlineInputBorder()),
                    onChanged: (typed) {
                      split.percents[unit.id] = typed;
                      onChanged();
                    },
                  ),
          Text('${words.expensesSplitTotal}: ${formatPlain(total)}%', key: totalKey, style: Theme.of(context).textTheme.titleSmall),
        ],
      ],
    );
  }
}
