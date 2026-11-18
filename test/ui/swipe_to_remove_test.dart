// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/swipe_to_remove.dart';
import 'package:redix/words/words.dart';

/// redix-app #88: a row a swipe would remove shows a red bar inside its card, on the edge the swipe starts from; a row that would not move shows none.
void main() {
  const row = Key('row');

  Future<void> pumpRow(WidgetTester tester, {required bool mayRemove, TextDirection direction = TextDirection.rtl}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_NoWords(), DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: SwipeToRemove(rowKey: row, mayRemove: mayRemove, onRemove: () async => '', child: const ListTile(key: row, title: Text('عهدة الموقع'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('redix-app #88 R1, R6: a row that may be removed has a red bar, in the theme\'s error color, inside its one card', (tester) async {
    await pumpRow(tester, mayRemove: true);

    final card = tester.getRect(find.byKey(row.card));
    final bar = tester.getRect(find.byKey(row.bar));
    expect(find.byType(Card), findsOneWidget);
    expect((card.contains(bar.topLeft), card.contains(bar.bottomRight - const Offset(1, 1))), (true, true), reason: 'the bar lies inside the card');
    expect(bar.width, SwipeToRemove.barWidth);
    final color = (tester.widget<PositionedDirectional>(find.byKey(row.bar)).child as ColoredBox).color;
    expect(color, Theme.of(tester.element(find.byKey(row))).colorScheme.error);
  });

  testWidgets('redix-app #88 R4: a row that may not be removed has its card and no bar, and does not move', (tester) async {
    await pumpRow(tester, mayRemove: false);

    expect(find.byKey(row.card), findsOneWidget);
    expect(find.byKey(row.bar), findsNothing);
    expect(find.byKey(row.swipe), findsNothing);
  });

  testWidgets('redix-app #88 R3, R5: the bar is on the edge the swipe starts from, the left in Arabic and the right in English', (tester) async {
    await pumpRow(tester, mayRemove: true);
    final arabicCard = tester.getRect(find.byKey(row.card));
    expect(tester.getRect(find.byKey(row.bar)).left, arabicCard.left);

    await pumpRow(tester, mayRemove: true, direction: TextDirection.ltr);
    final englishCard = tester.getRect(find.byKey(row.card));
    expect(tester.getRect(find.byKey(row.bar)).right, englishCard.right);
  });
}

/// Words that answer every key with itself, so the row draws without the API.
class _NoWords extends LocalizationsDelegate<Words> {
  const _NoWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Words> load(Locale locale) async => Words({});

  @override
  bool shouldReload(_NoWords old) => false;
}
