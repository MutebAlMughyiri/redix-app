import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redix/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const subtitles = {'ar': 'مصروفات المشاريع', 'en': 'Project expenses'};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  var online = true;
  final api = MockClient((request) async {
    if (!online) {
      throw http.ClientException('offline');
    }
    final language = request.url.pathSegments.last;
    final words = {'app.title': 'REDIX', 'app.subtitle': subtitles[language]};
    return http.Response.bytes(utf8.encode(jsonEncode(words)), 200, headers: {'etag': '"1"'});
  });

  Future<void> pumpIn(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await http.runWithClient(() => tester.pumpWidget(const RedixApp()), () => api);
    await tester.pumpAndSettle();
  }

  String subtitle(WidgetTester tester) => tester.widget<Text>(find.byKey(HomeScreen.subtitleKey)).data!;

  TextDirection direction(WidgetTester tester) => Directionality.of(tester.element(find.byKey(HomeScreen.subtitleKey)));

  testWidgets('home shows the Arabic words from the API, right to left', (tester) async {
    online = true;
    await pumpIn(tester, const Locale('ar'));

    expect(subtitle(tester), subtitles['ar']);
    expect(direction(tester), TextDirection.rtl);
  });

  testWidgets('home shows the English words from the API, left to right', (tester) async {
    online = true;
    await pumpIn(tester, const Locale('en'));

    expect(subtitle(tester), subtitles['en']);
    expect(direction(tester), TextDirection.ltr);
  });

  testWidgets('a phone in another language gets Arabic', (tester) async {
    online = true;
    await pumpIn(tester, const Locale('fr'));

    expect(subtitle(tester), subtitles['ar']);
  });

  testWidgets('a first start without a network shows no words, only a retry that loads them', (tester) async {
    online = false;
    await pumpIn(tester, const Locale('ar'));

    expect(find.byKey(HomeScreen.subtitleKey), findsNothing);
    expect(find.byKey(NoWordsScreen.iconKey), findsOneWidget);

    online = true;
    await http.runWithClient(() async {
      await tester.tap(find.byKey(NoWordsScreen.retryKey));
      await tester.pumpAndSettle();
    }, () => api);

    expect(subtitle(tester), subtitles['ar']);
  });
}
