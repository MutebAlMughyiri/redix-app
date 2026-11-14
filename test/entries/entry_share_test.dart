import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/entry_link_screen.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import '../app_harness.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/ui/api_list_body.dart';

/// Sharing an entry as text, with a link that opens it for approval (redix-app #83).
void main() {
  final date = formatDate(DateTime(2026, 11, 5));

  String linkOf(String entryId) => 'https://redix.test/projects/project-0/entries/$entryId/open';

  /// The project's القيود in [language], its entries arranged by [arrange], and the phone's share sheet.
  Future<({FakeApi api, FakeCapture capture})> openEntries(WidgetTester tester, void Function(FakeApi api) arrange, {String language = 'en'}) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: field);
    arrange(api);
    final capture = FakeCapture();
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture, locale: Locale(language));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.searchEntriesKey('project-0'))));
    return (api: api, capture: capture);
  }

  /// Shares the entry [entryId] from its sheet, and gives the text the share sheet was handed.
  Future<String> share(WidgetTester tester, ({FakeApi api, FakeCapture capture}) opened, String entryId) async {
    await act(tester, opened.api, () => tester.tap(find.byKey(EntriesScreen.rowKey(entryId))));
    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.shareKey)));
    return opened.capture.sharedTexts.single;
  }

  group('the text', () {
    for (final language in ['en', 'ar']) {
      testWidgets('R2, R4, R5, R6, R10: in $language, an entry\'s sheet in القيود shares it as text alone, every fact on its own line and its link last', (tester) async {
        final opened = await openEntries(tester, (api) => api.addEntry(description: 'الدفعة الأولى', paymentMethodName: 'شبكة'), language: language);

        expect(await share(tester, opened, 'entry-0'), [
          '$language entries.purchases · غصون 6',
          '$language entryShare.item: بند اللياسة',
          '$language entryShare.supplier: شركة البواني',
          '$language entryShare.amount: 1,150.00',
          '$language entryShare.date: $date',
          '$language entryShare.status: $language entries.pendingApproval',
          '$language entryShare.account: حساب المؤسسة',
          '$language entryShare.paymentMethod: شبكة',
          '$language entryShare.author: نواف',
          '$language entryShare.description: الدفعة الأولى',
          linkOf('entry-0'),
        ].join('\n'));
        expect(opened.capture.sharedOut, isEmpty, reason: 'text only: no file goes with it');
      });
    }

    for (final (kind, partnerName, lines) in [
      ('contractorPayment', '', ['en entries.contractorPayments · غصون 6', 'en entryShare.item: بند اللياسة', 'en entryShare.contractor: شركة البواني']),
      ('revenue', '', ['en categories.tableRevenue · غصون 6', 'en entryShare.item: بند اللياسة']),
      ('capitalIn', 'سالم', ['en capital.contribution · غصون 6', 'en entryShare.partner: سالم']),
      ('capitalOut', 'سالم', ['en capital.withdrawal · غصون 6', 'en entryShare.partner: سالم']),
    ]) {
      testWidgets('R3, R4: a $kind shares the same way, saying what it is and its table, and leaving out a payment method and notes it does not have', (tester) async {
        final opened = await openEntries(tester, (api) => api.addEntry(kind: kind, partnerName: partnerName, status: 'approved'));

        expect(await share(tester, opened, 'entry-0'), [
          ...lines,
          'en entryShare.amount: 1,150.00',
          'en entryShare.date: $date',
          'en entryShare.status: en entries.approved',
          'en entryShare.account: حساب المؤسسة',
          'en entryShare.author: نواف',
          linkOf('entry-0'),
        ].join('\n'));
      });
    }
  });

  group('the link', () {
    /// Starts the app with [permissions] in the project, its entries arranged by [arrange], and opens the link of the entry [entryId] of the project [projectId], as tapping it
    /// in WhatsApp does; signed out unless [isSignedIn].
    Future<FakeApi> follow(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance, String projectId = 'project-0', String entryId = 'entry-0', bool isSignedIn = true}) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = FakeApi()..addProject('غصون 6', permissions: permissions);
      arrange(api);
      await pumpRedix(tester, api, stored: isSignedIn ? {'session': keptSession} : const {});
      await act(tester, api, () async => GoRouter.of(tester.element(find.byKey(isSignedIn ? ProjectsScreen.sharedSettingsKey : SignInScreen.usernameKey))).go(EntryLinkScreen.pathOf(projectId, entryId)));
      return api;
    }


    testWidgets('R7, D7: for whoever decides entries, the link of one waiting opens Approvals on it alone, with Approve and Reject, everything waiting a tap away and the home behind', (tester) async {
      final api = await follow(tester, (api) {
        api
          ..addEntry()
          ..addPending()
          ..addPending();
      });

      expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
      expect(find.byKey(ApprovalsScreen.approveKey('entry-0')), findsOneWidget);
      expect(find.byKey(ApprovalsScreen.rejectKey('entry-0')), findsOneWidget);
      expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsNothing);

      await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.showAllKey)));

      expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsOneWidget);
      expect(find.byKey(ApprovalsScreen.showAllKey), findsNothing);

      await act(tester, api, () => tester.pageBack());

      expect(find.byKey(HomeScreen.searchEntriesKey('project-0')), findsOneWidget);
    });

    testWidgets('R8: for someone who cannot decide it, the link opens the entry read only, saying it waits, and never Approvals', (tester) async {
      await follow(tester, (api) => api.addEntry(isMine: false), permissions: reader);

      expect(tester.widget<Text>(find.byKey(AddEntryScreen.statusKey)).data, 'en entries.pendingApproval');
      expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
    });

    testWidgets('R8: an entry no longer waiting opens read only even for whoever decides entries, saying where it stands', (tester) async {
      await follow(tester, (api) => api.addEntry(status: 'rejected', rejectionReason: 'الصورة غير واضحة'));

      expect(tester.widget<Text>(find.byKey(AddEntryScreen.statusKey)).data, 'en entries.rejected');
      expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
    });

    testWidgets('R8: the link grants nothing by itself: signed out, it asks to sign in first, and then opens the entry', (tester) async {
      final api = await follow(tester, (api) {
        api
          ..addEntry()
          ..addPending();
      }, isSignedIn: false);

      expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
      expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);

      await act(tester, api, () async {
        await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
        await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
        await tester.tap(find.byKey(SignInScreen.submitKey));
      });

      expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
    });

    testWidgets('R9: a link that cannot be read says why and offers to try again, never that the entry is gone, and trying again opens it', (tester) async {
      final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance);
      api
        ..addEntry()
        ..addPending();
      await pumpRedix(tester, api, stored: {'session': keptSession});
      api.online = false;

      await act(tester, api, () async => GoRouter.of(tester.element(find.byKey(ProjectsScreen.sharedSettingsKey))).go(EntryLinkScreen.pathOf('project-0', 'entry-0')));

      expect(find.byKey(EntryLinkScreen.notFoundKey), findsNothing);
      expect(find.byKey(ApiListBody.retryKey), findsOneWidget);
      api.online = true;
      await act(tester, api, () => tester.tap(find.byKey(ApiListBody.retryKey)));
      expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
    });

    testWidgets('R8: signed out with a temporary password, the link opens once the password is changed', (tester) async {
      final api = await follow(tester, (api) {
        api
          ..mustChangePassword = true
          ..addEntry()
          ..addPending();
      }, isSignedIn: false);

      await act(tester, api, () async {
        await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
        await tester.enterText(find.byKey(SignInScreen.passwordKey), 'temporary');
        await tester.tap(find.byKey(SignInScreen.submitKey));
      });
      await act(tester, api, () async {
        await tester.enterText(find.byKey(ChangePasswordScreen.currentKey), 'temporary');
        await tester.enterText(find.byKey(ChangePasswordScreen.newKey), 'chosen-pass');
        await tester.enterText(find.byKey(ChangePasswordScreen.confirmKey), 'chosen-pass');
        await tester.tap(find.byKey(ChangePasswordScreen.submitKey));
      });

      expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
    });

    for (final (what, projectId, entryId) in [('an entry the project no longer lists', 'project-0', 'entry-9'), ('a project the reader is not in', 'project-7', 'entry-0')]) {
      testWidgets('R9: the link of $what says it cannot be found, and opens nothing', (tester) async {
        await follow(tester, (api) {
          api
            ..addEntry()
            ..addPending();
        }, projectId: projectId, entryId: entryId);

        expect(tester.widget<Text>(find.byKey(EntryLinkScreen.notFoundKey)).data, 'en entries.notFound');
        expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
        expect(find.byKey(AddEntryScreen.statusKey), findsNothing);
      });
    }
  });

  testWidgets('redix-app #89 R16: an entry its account does not cover says so in the shared text, without any balance', (tester) async {
    final opened = await openEntries(tester, (api) => api.addEntry(amount: 600, accountShortBy: 247));

    final shared = await share(tester, opened, 'entry-0');

    expect(shared, contains('en entryShare.accountShort'));
    expect(shared, isNot(contains('247')));
  });

  testWidgets('redix-app #89 R16: an entry its account covers has no such line', (tester) async {
    final opened = await openEntries(tester, (api) => api.addEntry(amount: 600));

    expect(await share(tester, opened, 'entry-0'), isNot(contains('entryShare.accountShort')));
  });
}
