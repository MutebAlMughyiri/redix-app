import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/api_list_body.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with its رأس المال, and متعب, whose own account is متعب المغيري, and هيثم, who has none, each a table of it, opened as far as its partners.
  Future<({FakeApi api, String mutab, String haitham})> openPartners(WidgetTester tester, {String status = 'active', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    final capital = api.addItem(api.addCategory('project-0', 'رأس المال'), 'رأس المال', type: 'capital')['id']! as String;
    api.addMember('user-mutab', 'متعب المغيري');
    api.addMember('user-nawaf', 'نواف');
    final mutab = api.addPartner('project-0', 'متعب', userId: 'user-mutab', userName: 'متعب المغيري', itemId: capital);
    final haitham = api.addPartner('project-0', 'هيثم', itemId: capital);
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));
    return (api: api, mutab: mutab['id'] as String, haitham: haitham['id'] as String);
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

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.editKey(opened.mutab))));
    expect(tester.widget<TextField>(find.byKey(PartnersScreen.partnerNameKey)).controller!.text, 'متعب');
    await save(tester, opened.api, 'متعب المغيري');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/partners/${opened.mutab}');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'متعب المغيري', 'userId': 'user-mutab'});
    expect(text(tester, PartnersScreen.nameKey(opened.mutab)), 'متعب المغيري');
  });

  testWidgets('editing can give an account, and take it away', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.editKey(opened.haitham))));
    await chooseMember(tester, opened.api, PartnersScreen.loginKey, 'user-nawaf');
    await save(tester, opened.api, 'هيثم');
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'نواف');

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.editKey(opened.haitham))));
    await chooseMember(tester, opened.api, PartnersScreen.loginKey, '');
    await save(tester, opened.api, 'هيثم');

    expect(opened.api.sentSettingsChanges.last.$2, {'name': 'هيثم'});
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'en partners.noLogin');
  });

  testWidgets('a project with no partners says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));

    expect(text(tester, ApiListBody.emptyKey), 'en partners.empty');
  });

  testWidgets('seeing all capital without keeping the settings shows them with nothing to change', (tester) async {
    final opened = await openPartners(tester, permissions: ['readProject', 'seeAllCapital']);

    expect(find.byKey(PartnersScreen.nameKey(opened.mutab)), findsOneWidget);
    expect(isEnabled(tester, PartnersScreen.addKey), isFalse);
    expect(find.byKey(PartnersScreen.editKey(opened.mutab)), findsNothing);
  });

  testWidgets('a finished project shows its partners with nothing to change', (tester) async {
    final opened = await openPartners(tester, status: 'finished');

    expect(find.byKey(PartnersScreen.nameKey(opened.mutab)), findsOneWidget);
    expect(isEnabled(tester, PartnersScreen.addKey), isFalse);
    expect(find.byKey(PartnersScreen.editKey(opened.mutab)), findsNothing);
  });

  testWidgets('everyone in the project has a way in, since each sees the total and the partners chosen for them (BR-31)', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await openProject(tester, api);

    expect(find.byKey(HomeScreen.partnersKey('project-0')), findsOneWidget);
  });

  testWidgets('with no network the list shows what was kept, and no failure', (tester) async {
    final opened = await openPartners(tester);
    opened.api.online = false;

    await act(tester, opened.api, () => tester.tap(find.byType(BackButton)));
    await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
    await act(tester, opened.api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));

    expect(find.byKey(ApiListBody.messageKey), findsNothing);
  });
}
