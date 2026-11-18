// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/words/no_words_screen.dart';

import 'app_harness.dart';

void main() {
  String title(WidgetTester tester) => tester.widget<Text>(find.byKey(ProjectsScreen.titleKey)).data!;

  TextDirection direction(WidgetTester tester) => Directionality.of(tester.element(find.byKey(ProjectsScreen.titleKey)));

  testWidgets('home shows the Arabic words from the API, right to left', (tester) async {
    await pumpRedix(tester, FakeApi(), locale: const Locale('ar'), stored: {'session': keptSession});

    expect(title(tester), 'ar projects.choose');
    expect(direction(tester), TextDirection.rtl);
  });

  testWidgets('home shows the English words from the API, left to right', (tester) async {
    await pumpRedix(tester, FakeApi(), stored: {'session': keptSession});

    expect(title(tester), 'en projects.choose');
    expect(direction(tester), TextDirection.ltr);
  });

  testWidgets('a phone in another language gets Arabic', (tester) async {
    await pumpRedix(tester, FakeApi(), locale: const Locale('fr'), stored: {'session': keptSession});

    expect(title(tester), 'ar projects.choose');
  });

  testWidgets('a first start without a network shows no words, only a retry that loads them', (tester) async {
    final api = FakeApi()..online = false;
    await pumpRedix(tester, api, stored: {'session': keptSession});

    expect(find.byKey(ProjectsScreen.titleKey), findsNothing);
    expect(find.byKey(NoWordsScreen.iconKey), findsOneWidget);

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(NoWordsScreen.retryKey)));

    expect(title(tester), 'en projects.choose');
  });
}
