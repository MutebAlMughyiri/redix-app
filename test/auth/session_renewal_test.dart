// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/session.dart';

import '../app_harness.dart';

void main() {
  const fifteenMinutes = Duration(minutes: 15);

  testWidgets('redix-api #126 R6: opening the app renews its kept session once', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});

    expect(api.refreshes, 1);
  });

  testWidgets('redix-api #126 R6: opening the app with no kept session renews nothing', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api);

    expect(api.refreshes, 0);
  });

  testWidgets('redix-api #126 R6: coming back to the screen renews the session, and the project list is read again', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await sendToBackground(tester, api);
    api
      ..refreshes = 0
      ..sentReads.clear();

    await bringBack(tester, api);

    expect(api.refreshes, 1);
    expect(api.sentReads, contains('/projects'));
  });

  testWidgets('redix-api #126 R6: going to the background renews nothing', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    api
      ..refreshes = 0
      ..sentReads.clear();

    await sendToBackground(tester, api);

    expect(api.refreshes, 0);
    expect(api.sentReads, isEmpty);
    await bringBack(tester, api);
  });

  testWidgets('redix-api #126 R6: a renewal that fails does not read the project list again', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await sendToBackground(tester, api);
    api
      ..refreshStatus = 500
      ..refreshes = 0
      ..sentReads.clear();

    await bringBack(tester, api);

    expect(api.refreshes, 1);
    expect(api.sentReads, isEmpty);
  });

  testWidgets('redix-api #126 R6: an API that refuses even a renewed token renews once for the refused project list and reads it once more, never renewing and reading in a loop', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await sendToBackground(tester, api);
    api
      ..expiredAccessTokens.add('new-access')
      ..refreshes = 0
      ..sentReads.clear();

    await bringBack(tester, api);

    expect(api.refreshes, 2, reason: 'one on coming back, one for the refused read of the project list');
    expect(api.sentReads.where((path) => path == '/projects'), hasLength(2), reason: 'read after coming back, and sent once more with the renewed token');
  });

  testWidgets('redix-api #126 R6: the session renews on its own 30 seconds before its access token runs out', (tester) async {
    final api = FakeApi()..accessTokenLifetime = fifteenMinutes;
    await pumpRedix(tester, api, stored: {'session': keptSession});
    api
      ..accessTokenLifetime = Duration.zero
      ..refreshes = 0;

    await act(tester, api, () => tester.pump(fifteenMinutes - Session.renewsBeforeExpiry + const Duration(seconds: 1)));

    expect(api.refreshes, 1);
  });

  testWidgets('redix-api #126 R6: the session does not renew on its own sooner than 30 seconds before its access token runs out', (tester) async {
    final api = FakeApi()..accessTokenLifetime = fifteenMinutes;
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    api.refreshes = 0;

    await act(tester, api, () => tester.pump(fifteenMinutes - Session.renewsBeforeExpiry - const Duration(seconds: 1)));

    expect(api.refreshes, 0);
    await act(tester, api, session.signOut);
  });

  testWidgets('redix-api #126 R6: a phone whose clock runs 20 minutes fast renews on time, by the API\'s clock, not at once and again forever', (tester) async {
    final api = FakeApi()
      ..accessTokenLifetime = fifteenMinutes
      ..serverClockBehind = const Duration(minutes: 20);
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    api.refreshes = 0;

    await act(tester, api, () => tester.pump(fifteenMinutes - Session.renewsBeforeExpiry - const Duration(seconds: 1)));
    final early = api.refreshes;
    api.accessTokenLifetime = Duration.zero;
    await act(tester, api, () => tester.pump(const Duration(seconds: 2)));

    expect([early, api.refreshes], [0, 1]);
    await act(tester, api, session.signOut);
  });

  testWidgets('redix-api #126 R6: one renewal waits at a time: renewing on coming back replaces the one the earlier answer set', (tester) async {
    final api = FakeApi()..accessTokenLifetime = fifteenMinutes;
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.pump(const Duration(minutes: 10)));
    await sendToBackground(tester, api);
    await bringBack(tester, api);
    api
      ..accessTokenLifetime = Duration.zero
      ..refreshes = 0;

    await act(tester, api, () => tester.pump(const Duration(minutes: 5)));
    expect(api.refreshes, 0, reason: 'the first answer would have renewed at 14:30');

    await act(tester, api, () => tester.pump(const Duration(minutes: 10)));
    expect(api.refreshes, 1, reason: 'the renewal at 10:00 set the next for 24:30');
  });

  testWidgets('redix-api #126 R6: signing out leaves no renewal waiting', (tester) async {
    final api = FakeApi()..accessTokenLifetime = fifteenMinutes;
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, session.signOut);
    api.refreshes = 0;

    await act(tester, api, () => tester.pump(fifteenMinutes));

    expect(api.refreshes, 0);
  });
}
