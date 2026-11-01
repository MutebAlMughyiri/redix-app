import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/words/no_words_screen.dart';

import 'app_harness.dart';

void main() {
  String subtitle(WidgetTester tester) => tester.widget<Text>(find.byKey(HomeScreen.subtitleKey)).data!;

  TextDirection direction(WidgetTester tester) => Directionality.of(tester.element(find.byKey(HomeScreen.subtitleKey)));

  testWidgets('home shows the Arabic words from the API, right to left', (tester) async {
    await pumpRedix(tester, FakeApi(), locale: const Locale('ar'), stored: {'session': keptSession});

    expect(subtitle(tester), 'ar app.subtitle');
    expect(direction(tester), TextDirection.rtl);
  });

  testWidgets('home shows the English words from the API, left to right', (tester) async {
    await pumpRedix(tester, FakeApi(), stored: {'session': keptSession});

    expect(subtitle(tester), 'en app.subtitle');
    expect(direction(tester), TextDirection.ltr);
  });

  testWidgets('a phone in another language gets Arabic', (tester) async {
    await pumpRedix(tester, FakeApi(), locale: const Locale('fr'), stored: {'session': keptSession});

    expect(subtitle(tester), 'ar app.subtitle');
  });

  testWidgets('a first start without a network shows no words, only a retry that loads them', (tester) async {
    final api = FakeApi()..online = false;
    await pumpRedix(tester, api, stored: {'session': keptSession});

    expect(find.byKey(HomeScreen.subtitleKey), findsNothing);
    expect(find.byKey(NoWordsScreen.iconKey), findsOneWidget);

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(NoWordsScreen.retryKey)));

    expect(subtitle(tester), 'en app.subtitle');
  });
}
