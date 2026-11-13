import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';

import '../app_harness.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/app_color.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  String status(WidgetTester tester, String id) =>
      tester.widget<Text>(find.descendant(of: find.byKey(ProjectsScreen.statusKey(id)), matching: find.byType(Text))).data!;

  Future<void> openProjects(WidgetTester tester, FakeApi api) async {
    await pumpRedix(tester, api, stored: {'session': keptSession});
  }

  testWidgets('with no projects yet, the list says what to do next', (tester) async {
    await openProjects(tester, FakeApi());

    expect(text(tester, ApiListBody.emptyKey), 'en projects.empty');
    expect(find.byKey(ProjectsScreen.newProjectKey), findsOneWidget);
  });

  testWidgets('without a network the list says so, and Try again reads it', (tester) async {
    final api = FakeApi()
      ..online = false
      ..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: keptWords('en'));
    expect(text(tester, ApiListBody.messageKey), 'en projects.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(ApiListBody.retryKey)));
    expect(find.byKey(ApiListBody.messageKey), findsNothing);
    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('Arabic names show as typed', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);

    expect(text(tester, ProjectsScreen.nameKey('project-0')), 'غصون 6');
  });

  testWidgets('an expired access token is renewed once for each list read at once, and the session stays open', (tester) async {
    final api = FakeApi()
      ..refreshStatus = 500
      ..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    api
      ..expiredAccessTokens.add('kept-access')
      ..refreshStatus = 200
      ..refreshes = 0
      ..sentAccessTokens.clear();

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

    expect(api.sentAccessTokens, [...List.filled(5, 'kept-access'), ...List.filled(10, 'new-access')], reason: 'each list sent again with the new token, and the project list read again after each renewal (redix-api #126 R6)');
    expect(api.refreshes, 5);
    expect(find.byKey(HomeScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('anyone signed in can register a project', (tester) async {
    await openProjects(tester, FakeApi());

    expect(find.byKey(ProjectsScreen.newProjectKey), findsOneWidget);
  });

  testWidgets('a project waiting for approval says so, does not open and has no star', (tester) async {
    final api = FakeApi()..addProject('غصون 8', status: 'pendingApproval', permissions: []);
    await openProjects(tester, api);

    expect(status(tester, 'project-0'), 'en projects.pending');
    expect(find.byKey(ProjectsScreen.starKey('project-0')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('a rejected project says why, does not open and has no star', (tester) async {
    final api = FakeApi()..addProject('غصون 9', status: 'rejected', rejectionReason: 'الاسم مكرر', permissions: []);
    await openProjects(tester, api);

    expect(status(tester, 'project-0'), 'en projects.rejected');
    expect(text(tester, ProjectsScreen.reasonKey('project-0')), 'الاسم مكرر');
    expect(find.byKey(ProjectsScreen.starKey('project-0')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('a card keeps its margins in Arabic, and on a waiting project with no star', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 8', status: 'pendingApproval', permissions: []);
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});

    final card = tester.getRect(find.byKey(ProjectsScreen.cardKey('project-0')));
    expect(card.right - tester.getRect(find.byKey(ProjectsScreen.nameKey('project-0'))).right, greaterThanOrEqualTo(16));

    final waiting = tester.getRect(find.byKey(ProjectsScreen.cardKey('project-1')));
    expect(tester.getRect(find.byKey(ProjectsScreen.statusKey('project-1'))).left - waiting.left, greaterThanOrEqualTo(16));
  });

  testWidgets('sign-in lands on the list, with no change buttons on it', (tester) async {
    await openProjects(tester, FakeApi()..addProject('غصون 6'));

    expect(text(tester, ProjectsScreen.titleKey), 'en projects.choose');
    expect(text(tester, ProjectsScreen.hintKey), 'en projects.chooseHint');
    expect(find.byKey(HomeScreen.sharedSettingsKey('project-0')), findsNothing);
  });

  testWidgets('a card shows its units, roles and status', (tester) async {
    await openProjects(tester, FakeApi()..addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الجنوبية']));

    expect(text(tester, ProjectsScreen.detailsKey('project-0')), 'الفلة الغربية · الفلة الجنوبية');
    expect(status(tester, 'project-0'), 'en projects.active');
  });

  testWidgets('a finished project says it is read-only', (tester) async {
    await openProjects(tester, FakeApi()..addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']));

    expect(text(tester, ProjectsScreen.detailsKey('project-0')), 'en projects.readOnly');
    expect(status(tester, 'project-0'), 'en projects.finished');
  });

  /// Two projects of the signed-in user, made inactive in the second, غصون 7 (redix-api #126).
  FakeApi activeAndInactive() {
    final api = FakeApi()..addProject('غصون 6');
    api.makeInactive(api.addProject('غصون 7'));
    return api;
  }

  Color? nameColor(WidgetTester tester, String id) => tester.widget<Text>(find.byKey(ProjectsScreen.nameKey(id))).style?.color;

  Color? chipColor(WidgetTester tester, String id) => tester.widget<Chip>(find.byKey(ProjectsScreen.statusKey(id))).backgroundColor;

  testWidgets('redix-api #126 D2: a project the user was made inactive in shows gray and disabled, saying so under its name, with no star, and does not open', (tester) async {
    final api = activeAndInactive();
    await openProjects(tester, api);
    final context = tester.element(find.byKey(ProjectsScreen.cardKey('project-1')));

    expect(text(tester, ProjectsScreen.detailsKey('project-1')), 'en projects.inactive');
    expect(nameColor(tester, 'project-1'), AppColor.quiet.of(context));
    expect(chipColor(tester, 'project-1'), AppColor.mutedSurface.of(context));
    expect(find.byKey(ProjectsScreen.starKey('project-1')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-1'))));
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(HomeScreen.titleKey), findsNothing);
  });

  testWidgets('redix-api #126 D2: the project beside it that the user is active in shows as before, with its units, its star and its green status, and opens', (tester) async {
    final api = activeAndInactive();
    await openProjects(tester, api);
    final context = tester.element(find.byKey(ProjectsScreen.cardKey('project-0')));

    expect(text(tester, ProjectsScreen.detailsKey('project-0')), 'en projects.noUnits');
    expect(nameColor(tester, 'project-0'), isNot(AppColor.quiet.of(context)));
    expect(chipColor(tester, 'project-0'), AppColor.activeSurface.of(context));
    expect(find.byKey(ProjectsScreen.starKey('project-0')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    expect(text(tester, HomeScreen.titleKey), 'غصون 6');
  });

  IconData star(WidgetTester tester, String id) => (tester.widget<IconButton>(find.byKey(ProjectsScreen.starKey(id))).icon as Icon).icon!;

  testWidgets('AC-37.1: the star makes a project the default, which opens at sign-in, and a message says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.starKey('project-0'))));

    expect(api.sentProjectChanges.single.$1, '/projects/project-0/default');
    expect(api.defaultProjectId, 'project-0');
    expect(star(tester, 'project-0'), Icons.star);
    expect(text(tester, messageKeyOf('projects.defaultSet').label), 'en projects.defaultSet');
  });

  testWidgets('the star on another project moves the default there', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7');
    await openProjects(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.starKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.starKey('project-1'))));

    expect(api.sentProjectChanges.last.$1, '/projects/project-1/default');
    expect(star(tester, 'project-0'), Icons.star_border);
    expect(star(tester, 'project-1'), Icons.star);
  });

  testWidgets('the star on the default clears it, so sign-in shows the list', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.starKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.starKey('project-0'))));

    expect(api.sentProjectChanges.last.$1, 'DELETE /projects/default');
    expect(api.defaultProjectId, '');
    expect(star(tester, 'project-0'), Icons.star_border);
  });

  testWidgets('a refused star says why, says nothing of a default, and stays empty', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);
    api.projectAnswer = (status: 403, code: '');

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.starKey('project-0'))));

    expect(text(tester, messageKeyOf('projects.refused').label), 'en projects.refused');
    expect(find.byKey(messageKeyOf('projects.defaultSet')), findsNothing);
    expect(star(tester, 'project-0'), Icons.star_border);
  });

  testWidgets('a star without a network says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.starKey('project-0'))));

    expect(find.text('en projects.noConnection'), findsOneWidget);
    expect(star(tester, 'project-0'), Icons.star_border);
  });
}
