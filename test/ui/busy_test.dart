import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/ui/busy.dart';

/// Muteb, 11 Nov 2026: a spinner while a file is picked, read or sent, through the one whileBusy.
void main() {
  /// The button the test taps to start the work.
  const goKey = Key('busyTest.go');

  Future<void> pumpButton(WidgetTester tester, Future<String> Function(BuildContext context) onTap) =>
      tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => TextButton(key: goKey, onPressed: () => onTap(context), child: const Text('go')))));

  testWidgets('a spinner covers the screen while the work runs, and goes once it ends, answering what the work answered', (tester) async {
    final work = Completer<String>();
    var answer = '';
    await pumpButton(tester, (context) async => answer = await whileBusy(context, work.future));

    await tester.tap(find.byKey(goKey));
    await tester.pump();
    expect(find.byKey(busySpinnerKey), findsOneWidget);

    work.complete('kept');
    await tester.pumpAndSettle();
    expect(find.byKey(busySpinnerKey), findsNothing);
    expect(answer, 'kept');
  });

  testWidgets('a work that fails takes its spinner away too, and its failure reaches the caller', (tester) async {
    final work = Completer<String>();
    Object failure = '';
    await pumpButton(tester, (context) => whileBusy(context, work.future).catchError((Object error) {
      failure = error;
      return '';
    }));

    await tester.tap(find.byKey(goKey));
    await tester.pump();
    work.completeError(StateError('lost'));
    await tester.pumpAndSettle();

    expect(find.byKey(busySpinnerKey), findsNothing);
    expect(failure, isA<StateError>());
  });

  testWidgets('while the spinner shows, the back button does not take it away', (tester) async {
    final work = Completer<String>();
    await pumpButton(tester, (context) => whileBusy(context, work.future));

    await tester.tap(find.byKey(goKey));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(busySpinnerKey), findsOneWidget);

    work.complete('');
    await tester.pumpAndSettle();
    expect(find.byKey(busySpinnerKey), findsNothing);
  });
}
