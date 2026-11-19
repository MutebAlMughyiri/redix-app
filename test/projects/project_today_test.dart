// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/server_clock.dart';
import 'package:redix/projects/project.dart';

import '../app_harness.dart';

void main() {
  Project projectIn(Map<String, Object> zone) => Project.fromJson({
    'id': 'project-0', 'name': 'مشروع A', 'startDate': '2026-11-01', 'status': 'active', 'rejectionReason': '', 'description': '', 'isInactive': false,
    'holdsEntries': false, 'units': <Object>[], 'permissions': <Object>[], ...zone,
  });

  final clock = ServerClock(MemoryStore(), () => DateTime.utc(2026, 11, 16, 17));

  test('redix-app #107, BR-12: a project\'s today is the server\'s clock in its zone: at 17:00 UTC it is the 17th in Shanghai, the 16th in Riyadh and New York', () {
    expect(projectIn({'timeZone': 'Asia/Shanghai', 'utcOffsetMinutes': 480}).todayBy(clock), DateTime(2026, 11, 17));
    expect(projectIn({'timeZone': 'Asia/Riyadh', 'utcOffsetMinutes': 180}).todayBy(clock), DateTime(2026, 11, 16));
    expect(projectIn({'timeZone': 'America/New_York', 'utcOffsetMinutes': -300}).todayBy(clock), DateTime(2026, 11, 16));
  });

  test('redix-app #107 D1: a project kept on the phone before zones came is in Riyadh', () {
    final kept = projectIn({});

    expect((kept.timeZone, kept.utcOffsetMinutes), ('Asia/Riyadh', 180));
    expect(kept.todayBy(clock), DateTime(2026, 11, 16));
  });
}
