// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:io' show HttpDate;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:redix/auth/server_clock.dart';

import '../app_harness.dart';

void main() {
  http.Response answeredAt(DateTime server) => http.Response('', 200, headers: {'date': HttpDate.format(server)});

  test('redix-app #107 D2: the clock learns how far the phone is from the server, and keeps it for a phone opened with no network', () async {
    final store = MemoryStore();
    var phone = DateTime.utc(2026, 11, 16, 10);
    final clock = ServerClock(store, () => phone);
    await clock.learn(answeredAt(DateTime.utc(2026, 11, 17, 4)));

    expect(clock.now(), DateTime.utc(2026, 11, 17, 4));
    phone = phone.add(const Duration(hours: 1));
    expect(clock.now(), DateTime.utc(2026, 11, 17, 5));

    final reopened = ServerClock(store, () => phone);
    await reopened.open();
    expect(reopened.now(), DateTime.utc(2026, 11, 17, 5));
  });

  test('redix-app #107: an answer that says no time teaches nothing, and a phone that never heard one keeps its own clock', () async {
    final phone = DateTime.utc(2026, 11, 16, 10);
    final clock = ServerClock(MemoryStore(), () => phone);
    await clock.open();
    await clock.learn(http.Response('', 200));

    expect(clock.now(), phone);
  });
}
