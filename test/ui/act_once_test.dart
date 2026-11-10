import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/ui/act_once.dart';

const first = Key('first');
const second = Key('second');

Future<void> show(WidgetTester tester, TapAction? firstAction, [TapAction? secondAction]) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ActOnce(
        builder: (once) => Column(
          children: [
            TextButton(key: first, onPressed: once(firstAction), child: const Text('first')),
            TextButton(key: second, onPressed: once(secondAction), child: const Text('second')),
          ],
        ),
      ),
    ),
  ),
);

bool isGray(WidgetTester tester, Key key) => tester.widget<TextButton>(find.byKey(key)).onPressed == null;

void main() {
  testWidgets('the first tap runs the action, and the button stays gray until it ends', (tester) async {
    final done = Completer<void>();
    var runs = 0;
    await show(tester, () {
      runs++;
      return done.future;
    });

    await tester.tap(find.byKey(first));
    await tester.pump();

    expect(runs, 1);
    expect(isGray(tester, first), isTrue);
  });

  testWidgets('a second tap in the same frame does not run it again', (tester) async {
    var runs = 0;
    await show(tester, () async {
      runs++;
      await Completer<void>().future;
    });

    final onPressed = tester.widget<TextButton>(find.byKey(first)).onPressed!;
    onPressed();
    onPressed();
    await tester.pump();

    expect(runs, 1);
  });

  testWidgets('once the action ends the button works again', (tester) async {
    final done = Completer<void>();
    await show(tester, () => done.future);
    await tester.tap(find.byKey(first));
    await tester.pump();

    done.complete();
    await tester.pump();

    expect(isGray(tester, first), isFalse);
  });

  testWidgets('every button of one ActOnce grays while one of them runs', (tester) async {
    var otherRuns = 0;
    await show(tester, () => Completer<void>().future, () => otherRuns++);

    await tester.tap(find.byKey(first));
    await tester.pump();

    expect(isGray(tester, second), isTrue);
    await tester.tap(find.byKey(second), warnIfMissed: false);
    expect(otherRuns, 0);
  });

  testWidgets('a button with no action is gray from the start', (tester) async {
    await show(tester, null);

    expect(isGray(tester, first), isTrue);
  });

  testWidgets('an action that ends after its screen has gone does nothing more', (tester) async {
    final done = Completer<void>();
    await show(tester, () => done.future);
    await tester.tap(find.byKey(first));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    done.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
