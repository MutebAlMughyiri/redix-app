import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partner_history_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/bottom_button.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/app_color.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with its رأس المال, and متعب, whose own account is متعب المغيري, and هيثم, who has none, each a table of it, opened as far as its partners.
  Future<({FakeApi api, String mutab, String haitham})> openPartners(WidgetTester tester, {String status = 'active', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    final capital = api.addItem(api.addCategory('project-0', 'رأس المال'), 'رأس المال', type: 'capital')['id']! as String;
    api.addMember('user-mutab', 'متعب المغيري');
    api.addMember('user-nawaf', 'نواف');
    final mutab = api.addPartner('project-0', 'متعب', userId: 'user-mutab', userName: 'متعب المغيري', itemId: capital);
    final haitham = api.addPartner('project-0', 'هيثم', itemId: capital, mayDelete: false);
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.partnersKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.partnersKey('project-0'));
    return (api: api, mutab: mutab['id'] as String, haitham: haitham['id'] as String);
  }

  Future<void> openEdit(WidgetTester tester, FakeApi api, String id) async {
    await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.menuKey(id))));
    await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.editKey)));
  }

  Future<void> save(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.enterText(find.byKey(PartnersScreen.partnerNameKey), name);
    await tester.tap(find.byKey(ChangeDialog.saveKey));
  });

  testWidgets('each partner shows their own account, or that they have none, and their share', (tester) async {
    final opened = await openPartners(tester);

    expect(text(tester, PartnersScreen.nameKey(opened.mutab)), 'متعب');
    expect(text(tester, PartnersScreen.detailsKey(opened.mutab)), 'متعب المغيري');
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'en partners.noLogin');
    expect(find.byKey(PartnersScreen.shareKey(opened.mutab)), findsOneWidget);
  });

  testWidgets('redix-api #106: adding asks the name and the account, and no capital item; with no account chosen it sends the name alone', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.addKey)));
    expect(find.descendant(of: find.byType(ChangeDialog), matching: find.byType(TextField)), findsOneWidget);
    expect(text(tester, PartnersScreen.loginHintKey), 'en partners.loginHint');
    await save(tester, opened.api, 'نوف');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/partners');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'نوف'});
    expect(find.text('نوف'), findsOneWidget);
    expect(find.byKey(PartnersScreen.partnerNameKey), findsNothing);
  });

  testWidgets('the account is chosen from the list of the project\'s people, and sent', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.addKey)));
    await chooseMember(tester, opened.api, PartnersScreen.loginKey, 'user-nawaf');
    await save(tester, opened.api, 'نواف');

    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'نواف', 'userId': 'user-nawaf'});
  });

  testWidgets('a refusal stays in the dialog with its reason', (tester) async {
    final opened = await openPartners(tester);
    opened.api.settingsAnswer = (status: 400, code: 'userTaken');

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.addKey)));
    await chooseMember(tester, opened.api, PartnersScreen.loginKey, 'user-mutab');
    await save(tester, opened.api, 'متعب الثاني');

    expect(text(tester, ChangeDialog.messageKey), 'en partners.userTaken');
    expect(find.byKey(PartnersScreen.partnerNameKey), findsOneWidget);
  });

  testWidgets('editing starts from the partner and renames them, keeping their account', (tester) async {
    final opened = await openPartners(tester);

    await openEdit(tester, opened.api, opened.mutab);
    expect(tester.widget<TextField>(find.byKey(PartnersScreen.partnerNameKey)).controller!.text, 'متعب');
    await save(tester, opened.api, 'متعب المغيري');

    expect(opened.api.sentSettingsChanges.single.$1, 'PUT /projects/project-0/partners/${opened.mutab}');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'متعب المغيري', 'userId': 'user-mutab'});
    expect(text(tester, PartnersScreen.nameKey(opened.mutab)), 'متعب المغيري');
  });

  testWidgets('editing can give an account, and take it away', (tester) async {
    final opened = await openPartners(tester);

    await openEdit(tester, opened.api, opened.haitham);
    await chooseMember(tester, opened.api, PartnersScreen.loginKey, 'user-nawaf');
    await save(tester, opened.api, 'هيثم');
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'نواف');

    await openEdit(tester, opened.api, opened.haitham);
    await chooseMember(tester, opened.api, PartnersScreen.loginKey, '');
    await save(tester, opened.api, 'هيثم');

    expect(opened.api.sentSettingsChanges.last.$2, {'name': 'هيثم'});
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'en partners.noLogin');
  });

  testWidgets('redix-api #100: each row ends in ⋮ with Edit and Delete, and has no pencil; Delete asks first, then the partner leaves and it says so', (tester) async {
    final opened = await openPartners(tester);

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.menuKey(opened.mutab))));
    expect(find.byKey(PartnersScreen.editKey), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.deleteKey)));
    expect(find.text('en partners.deleteKeepsMovements'), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(opened.api.sentSettingsChanges.single.$1, 'DELETE /projects/project-0/partners/${opened.mutab}');
    expect(find.byKey(PartnersScreen.nameKey(opened.mutab)), findsNothing);
    expect(find.byKey(messageKeyOf('partners.deleted')), findsOneWidget);
  });

  testWidgets('redix-api #100: a partner with capital or something waiting has Delete gray, saying why, and nothing is sent', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.menuKey(opened.haitham))));
    expect(tester.widget<PopupMenuItem<VoidCallback>>(find.byKey(PartnersScreen.deleteKey)).enabled, isFalse);
    expect(find.text('en partners.partnerNotDeletable'), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.deleteKey), warnIfMissed: false));

    expect(opened.api.sentSettingsChanges, isEmpty);
  });

  testWidgets("findings row 206: on a shaded row the ⋮ menu's gray Delete keeps the menu's ground, its reason a line under its name", (tester) async {
    final opened = await openPartners(tester);
    final row = tester.element(find.byKey(PartnersScreen.nameKey(opened.haitham)));
    expect(Theme.of(row).cardTheme.color, AppColor.oddRow.of(row), reason: 'هيثم is on a shaded row');

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.menuKey(opened.haitham))));

    expect(find.descendant(of: find.byKey(PartnersScreen.deleteKey), matching: find.byType(ListTile)), findsNothing);
    expect(text(tester, PartnersScreen.deleteKey.label), 'en partners.delete');
    expect(text(tester, PartnersScreen.deleteKey.subtitle), 'en partners.partnerNotDeletable');
  });

  testWidgets("findings row 199: a partner held by someone else's draft has Delete gray, saying whose draft holds them", (tester) async {
    final opened = await openPartners(tester);
    final nour = opened.api.addPartner('project-0', 'نور', mayDelete: false, othersDrafts: ['نواف'])['id']! as String;
    await act(tester, opened.api, () => tester.pageBack());
    await scrollAndTap(tester, opened.api, HomeScreen.partnersKey('project-0'));

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.menuKey(nour))));

    expect(tester.widget<PopupMenuItem<VoidCallback>>(find.byKey(PartnersScreen.deleteKey)).enabled, isFalse);
    expect(text(tester, PartnersScreen.deleteKey.subtitle), 'en partners.partnerNotDeletable · en partners.draftsBy نواف');
  });

  testWidgets("findings row 199: Delete lists the person's own drafts naming the partner, which go with them", (tester) async {
    final opened = await openPartners(tester);
    final nour = opened.api.addPartner('project-0', 'نور', myDrafts: [{'entryDate': '2026-11-10', 'amount': 300}])['id']! as String;
    await act(tester, opened.api, () => tester.pageBack());
    await scrollAndTap(tester, opened.api, HomeScreen.partnersKey('project-0'));

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.menuKey(nour))));
    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.deleteKey)));

    expect(find.text('en partners.deleteKeepsMovements\n\nen partners.deleteRemovesMyDrafts\n${formatDate(DateTime(2026, 11, 10))} · ${formatMoney(300)}'), findsOneWidget);
  });

  testWidgets("findings row 202: without Delete entries, a partner one's own draft names has Delete gray, saying that deleting the draft needs it", (tester) async {
    final opened = await openPartners(tester, permissions: [for (final permission in managerAndFinance) if (permission != 'deleteEntries') permission]);
    final nour = opened.api.addPartner('project-0', 'نور', mayDelete: false, myDrafts: [{'entryDate': '2026-11-10', 'amount': 300}])['id']! as String;
    await act(tester, opened.api, () => tester.pageBack());
    await scrollAndTap(tester, opened.api, HomeScreen.partnersKey('project-0'));

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.menuKey(nour))));

    expect(tester.widget<PopupMenuItem<VoidCallback>>(find.byKey(PartnersScreen.deleteKey)).enabled, isFalse);
    expect(text(tester, PartnersScreen.deleteKey.subtitle), 'en partners.partnerNotDeletable · en partners.myDraftsNeedDeleteEntries');
  });

  testWidgets('findings row 202: a partner held for another reason does not blame Delete entries on whoever holds it', (tester) async {
    final opened = await openPartners(tester);
    final nour = opened.api.addPartner('project-0', 'نور', mayDelete: false, myDrafts: [{'entryDate': '2026-11-10', 'amount': 300}])['id']! as String;
    await act(tester, opened.api, () => tester.pageBack());
    await scrollAndTap(tester, opened.api, HomeScreen.partnersKey('project-0'));

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.menuKey(nour))));

    expect(text(tester, PartnersScreen.deleteKey.subtitle), 'en partners.partnerNotDeletable');
  });

  testWidgets('redix-app #101: Partners has + and History in the title bar and no bottom button; + adds a partner', (tester) async {
    final opened = await openPartners(tester);

    expect(find.byType(BottomButton), findsNothing);
    expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(PartnersScreen.addKey)), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(PartnersScreen.historyKey)), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.addKey)));

    expect(find.byKey(PartnersScreen.partnerNameKey), findsOneWidget);
  });

  testWidgets('redix-app #101: History lists the partners\' lines, a chip per partner, and one partner\'s chip asks for theirs alone', (tester) async {
    final opened = await openPartners(tester);
    opened.api
      ..addPartnerHistoryLine('project-0', 'capitalIn', partnerId: opened.mutab, partner: 'متعب', account: 'حساب المؤسسة', amount: 1000)
      ..addPartnerHistoryLine('project-0', 'partnerCreated', partnerId: opened.mutab, partner: 'متعب');

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.historyKey)));
    expect(find.byKey(PartnerHistoryScreen.lineKey(2000)), findsOneWidget);
    expect(find.byKey(PartnerHistoryScreen.lineKey(1999)), findsOneWidget);
    await openFilters(tester, opened.api);
    await act(tester, opened.api, () => tester.tap(find.byKey(PartnerHistoryScreen.partnerChoiceKey)));
    expect(find.byKey(PartnerHistoryScreen.partnerKey(opened.haitham)), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(PartnerHistoryScreen.partnerKey(opened.mutab))));

    expect(opened.api.historyReads.last.queryParameters['partner'], opened.mutab);
    expect(opened.api.historyReads.last.path, '/projects/project-0/partners/history');
  });

  testWidgets('a project with no partners says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.partnersKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.partnersKey('project-0'));

    expect(text(tester, ApiListBody.emptyKey), 'en partners.empty');
  });

  testWidgets('seeing all capital without keeping the settings shows them with nothing to change', (tester) async {
    final opened = await openPartners(tester, permissions: ['readProject', 'seeAllCapital']);

    expect(find.byKey(PartnersScreen.nameKey(opened.mutab)), findsOneWidget);
    expect(isEnabled(tester, PartnersScreen.addKey), isFalse);
    expect(find.byKey(PartnersScreen.menuKey(opened.mutab)), findsNothing);
  });

  testWidgets('a finished project shows its partners with nothing to change', (tester) async {
    final opened = await openPartners(tester, status: 'finished');

    expect(find.byKey(PartnersScreen.nameKey(opened.mutab)), findsOneWidget);
    expect(isEnabled(tester, PartnersScreen.addKey), isFalse);
    expect(find.byKey(PartnersScreen.menuKey(opened.mutab)), findsNothing);
  });

  testWidgets('everyone in the project has a way in, since each sees the total and the partners chosen for them (BR-31)', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await openProject(tester, api);

    await showProjectSetting(tester, HomeScreen.partnersKey('project-0'));
    expect(find.byKey(HomeScreen.partnersKey('project-0')), findsOneWidget);
  });

  testWidgets('with no network the list shows what was kept, and no failure', (tester) async {
    final opened = await openPartners(tester);
    opened.api.online = false;

    await act(tester, opened.api, () => tester.tap(find.byType(BackButton)));
    await showProjectSetting(tester, HomeScreen.partnersKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, opened.api, HomeScreen.partnersKey('project-0'));

    expect(find.byKey(ApiListBody.messageKey), findsNothing);
  });
}
