import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/projects/projects_screen.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with متعب, who has a login, and هيثم, who has none, opened as far as its partners.
  Future<({FakeApi api, String mutab, String haitham})> openPartners(WidgetTester tester, {String status = 'running', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    api.addMember('user-mutab', 'متعب المغيري');
    api.addMember('user-nawaf', 'نواف');
    final mutab = api.addPartner('project-0', 'متعب', userId: 'user-mutab', userName: 'متعب المغيري');
    final haitham = api.addPartner('project-0', 'هيثم');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));
    return (api: api, mutab: mutab['id'] as String, haitham: haitham['id'] as String);
  }

  Future<void> chooseLogin(WidgetTester tester, FakeApi api, String userId) async {
    await tester.ensureVisible(find.byKey(MemberPicker.optionKey(userId)));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(MemberPicker.optionKey(userId))));
  }

  Future<void> save(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.enterText(find.byKey(PartnersScreen.partnerNameKey), name);
    await tester.tap(find.byKey(PartnersScreen.saveKey));
  });

  testWidgets('each partner shows their login, or that they have none', (tester) async {
    final opened = await openPartners(tester);

    expect(text(tester, PartnersScreen.nameKey(opened.mutab)), 'متعب');
    expect(text(tester, PartnersScreen.detailsKey(opened.mutab)), 'متعب المغيري');
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'en partners.noLogin');
  });

  testWidgets('adding by name alone sends no login', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.addKey)));
    await save(tester, opened.api, 'نوف');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/partners');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'نوف'});
    expect(find.text('نوف'), findsOneWidget);
    expect(find.byKey(PartnersScreen.partnerNameKey), findsNothing);
  });

  testWidgets('adding with a login sends it, and says what it is for', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.addKey)));
    expect(text(tester, PartnersScreen.loginHintKey), 'en partners.loginHint');
    await chooseLogin(tester, opened.api, 'user-nawaf');
    await save(tester, opened.api, 'نواف');

    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'نواف', 'userId': 'user-nawaf'});
  });

  testWidgets('a refusal stays in the dialog with its reason', (tester) async {
    final opened = await openPartners(tester);
    opened.api.settingsAnswer = (status: 400, code: 'userTaken');

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.addKey)));
    await chooseLogin(tester, opened.api, 'user-mutab');
    await save(tester, opened.api, 'متعب الثاني');

    expect(text(tester, PartnersScreen.dialogMessageKey), 'en partners.userTaken');
    expect(find.byKey(PartnersScreen.partnerNameKey), findsOneWidget);
  });

  testWidgets('editing starts from the partner and renames them', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.editKey(opened.mutab))));
    expect(tester.widget<TextField>(find.byKey(PartnersScreen.partnerNameKey)).controller!.text, 'متعب');
    await save(tester, opened.api, 'متعب المغيري');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/partners/${opened.mutab}');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'متعب المغيري', 'userId': 'user-mutab'});
    expect(text(tester, PartnersScreen.nameKey(opened.mutab)), 'متعب المغيري');
  });

  testWidgets('editing can give a login, and take it away', (tester) async {
    final opened = await openPartners(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.editKey(opened.haitham))));
    await chooseLogin(tester, opened.api, 'user-nawaf');
    await save(tester, opened.api, 'هيثم');
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'نواف');

    await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.editKey(opened.haitham))));
    await chooseLogin(tester, opened.api, '');
    await save(tester, opened.api, 'هيثم');

    expect(opened.api.sentSettingsChanges.last.$2, {'name': 'هيثم'});
    expect(text(tester, PartnersScreen.detailsKey(opened.haitham)), 'en partners.noLogin');
  });

  testWidgets('a project with no partners says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));

    expect(text(tester, PartnersScreen.emptyKey), 'en partners.empty');
  });

  testWidgets('seeing all capital without keeping the settings shows them with nothing to change', (tester) async {
    final opened = await openPartners(tester, permissions: ['readProject', 'seeAllCapital']);

    expect(find.byKey(PartnersScreen.nameKey(opened.mutab)), findsOneWidget);
    expect(find.byKey(PartnersScreen.addKey), findsNothing);
    expect(find.byKey(PartnersScreen.editKey(opened.mutab)), findsNothing);
  });

  testWidgets('a finished project shows its partners with nothing to change', (tester) async {
    final opened = await openPartners(tester, status: 'finished');

    expect(find.byKey(PartnersScreen.nameKey(opened.mutab)), findsOneWidget);
    expect(find.byKey(PartnersScreen.addKey), findsNothing);
    expect(find.byKey(PartnersScreen.editKey(opened.mutab)), findsNothing);
  });

  testWidgets('without seeAllCapital there is no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await pumpRedix(tester, api, stored: {'session': keptSession});

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

    expect(find.byKey(HomeScreen.partnersKey('project-0')), findsNothing);
  });

  testWidgets('a list that cannot be read says so', (tester) async {
    final opened = await openPartners(tester);
    opened.api.online = false;

    await act(tester, opened.api, () => tester.tap(find.byType(BackButton)));
    await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
    await act(tester, opened.api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));

    expect(text(tester, PartnersScreen.messageKey), 'en partners.loadFailed');
  });
}
