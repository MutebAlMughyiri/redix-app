import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/liquidation_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';

import '../app_harness.dart';

void main() {
  Map<String, Object> part(String partnerId, String name, double share, double amount) => {'partnerId': partnerId, 'name': name, 'sharePercent': share, 'amount': amount};

  Future<FakeApi> openLiquidation(WidgetTester tester, void Function(FakeApi api) arrange, {String status = 'running'}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, units: ['الفلة']);
    arrange(api);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.liquidateKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.liquidateKey('project-0'))));
    return api;
  }

  Future<void> tapVisible(WidgetTester tester, FakeApi api, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(key)));
  }

  bool confirmEnabled(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(LiquidationScreen.confirmKey)).onPressed != null;

  testWidgets('UC-061: each part is paid out or carried as chosen, and liquidating sends how each goes', (tester) async {
    late String bank;
    late String laterPartner;
    late String laterBank;
    final api = await openLiquidation(tester, (api) {
      api.liquidationAnswer = {
        'surplus': 900,
        'pendingCount': 0,
        'parts': [part('partner-a', 'سالم', 60, 540), part('partner-b', 'فهد', 40, 360)],
        'distributed': <Map<String, Object>>[],
      };
      bank = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
      api.addProject('غصون 7');
      laterPartner = api.addPartner('project-1', 'فهد')['id']! as String;
      laterBank = api.addAccount('project-1', 'حساب غصون 7')['id']! as String;
    });
    expect(tester.widget<Text>(find.byKey(LiquidationScreen.surplusKey)).data, '900.00');
    expect(confirmEnabled(tester), isFalse);

    await tapVisible(tester, api, LiquidationScreen.accountKey('partner-a', bank));
    await tapVisible(tester, api, LiquidationScreen.carryKey('partner-b'));
    await tapVisible(tester, api, LiquidationScreen.accountKey('partner-b', bank));
    await tapVisible(tester, api, LiquidationScreen.targetProjectKey('partner-b', 'project-1'));
    await tapVisible(tester, api, LiquidationScreen.targetPartnerKey('partner-b', laterPartner));
    await tapVisible(tester, api, LiquidationScreen.targetAccountKey('partner-b', laterBank));
    await tapVisible(tester, api, LiquidationScreen.confirmKey);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    final (path, body) = api.sentMoney.single;
    expect(path, '/projects/project-0/liquidation');
    expect(body['lines'], [
      {'partnerId': 'partner-a', 'accountId': bank},
      {'partnerId': 'partner-b', 'accountId': bank, 'targetProjectId': 'project-1', 'targetPartnerId': laterPartner, 'targetAccountId': laterBank},
    ]);
    expect(find.text('en liquidation.done'), findsOneWidget);
  });

  testWidgets('BR-35: entries waiting for approval hold the liquidation, and say how many', (tester) async {
    await openLiquidation(tester, (api) {
      api.liquidationAnswer = {'surplus': 100, 'pendingCount': 2, 'parts': <Map<String, Object>>[], 'distributed': <Map<String, Object>>[]};
    });

    expect(tester.widget<Text>(find.byKey(LiquidationScreen.pendingKey)).data, 'en liquidation.pending');
    expect(confirmEnabled(tester), isFalse);
  });

  testWidgets('BR-27: a deficit says so, and shows what is to be paid in', (tester) async {
    await openLiquidation(tester, (api) {
      api.liquidationAnswer = {'surplus': -200, 'pendingCount': 0, 'parts': [part('partner-a', 'سالم', 100, -200)], 'distributed': <Map<String, Object>>[]};
    });

    expect(find.text('en liquidation.deficit'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(LiquidationScreen.surplusKey)).data, '200.00');
  });

  testWidgets('a refusal says why, and nothing closes', (tester) async {
    late String bank;
    final api = await openLiquidation(tester, (api) {
      api
        ..liquidationAnswer = {'surplus': 100, 'pendingCount': 0, 'parts': [part('partner-a', 'سالم', 100, 100)], 'distributed': <Map<String, Object>>[]}
        ..moneyAnswer = (status: 409, code: 'pendingEntries');
      bank = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
    });

    await tapVisible(tester, api, LiquidationScreen.accountKey('partner-a', bank));
    await tapVisible(tester, api, LiquidationScreen.confirmKey);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(tester.widget<Text>(find.byKey(LiquidationScreen.messageKey)).data, 'en capital.pendingEntries');
    expect(find.byType(LiquidationScreen), findsOneWidget);
  });

  testWidgets('a closed project shows what each partner was given', (tester) async {
    await openLiquidation(tester, (api) {
      api.liquidationAnswer = {
        'surplus': 0,
        'pendingCount': 0,
        'parts': <Map<String, Object>>[],
        'distributed': [
          {'entryId': 'entry-9', 'partnerName': 'سالم', 'date': '2026-11-05', 'amount': 540, 'accountName': 'حساب المؤسسة'},
        ],
      };
    }, status: 'finished');

    expect(find.descendant(of: find.byKey(LiquidationScreen.distributedKey('entry-9')), matching: find.text('540.00')), findsOneWidget);
    expect(find.byKey(LiquidationScreen.confirmKey), findsNothing);
  });
}
