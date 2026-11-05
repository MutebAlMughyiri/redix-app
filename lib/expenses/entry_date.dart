import 'package:flutter/material.dart';

import '../projects/project.dart';

/// Asks for an entry's date in [project], from [current]: within its period and not in the future (BR-12). Left without choosing, it answers [current].
Future<DateTime> pickEntryDate(BuildContext context, Project project, DateTime current) async {
  final today = DateTime.now();
  final start = project.startDate;
  final first = start.isBefore(today) ? start : today;
  final initial = current.isBefore(first) || current.isAfter(today) ? today : current;
  return await showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: today) ?? current;
}
