// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../auth/server_clock.dart';
import '../projects/project.dart';

/// Asks for an entry's date in [project], from [current]: within its period and not after its today by [clock] (BR-12, redix-app #107). Left without choosing, it
/// answers [current].
Future<DateTime> pickEntryDate(BuildContext context, Project project, ServerClock clock, DateTime current) async {
  final today = project.todayBy(clock);
  final start = project.startDate;
  final first = start.isBefore(today) ? start : today;
  final initial = current.isBefore(first) || current.isAfter(today) ? today : current;
  return await showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: today) ?? current;
}
