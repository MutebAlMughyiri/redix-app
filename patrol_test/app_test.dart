import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/main.dart';

void main() {
  patrolTest('the real app opens on its home screen with its words from the API', ($) async {
    await $.pumpWidgetAndSettle(const RedixApp());
    await $(HomeScreen.titleKey).waitUntilVisible();

    expect($(HomeScreen.subtitleKey), findsOneWidget);
    await $.takeNativeScreenshot('home');
  });
}
