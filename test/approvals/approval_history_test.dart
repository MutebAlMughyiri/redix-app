// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approval_history_screen.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/screen_title.dart';

import '../app_harness.dart';

/// The owner, 12 Nov 2026: "add history feature for wait approval feature": السجل from the title bar of بانتظار الاعتماد, as the accounts' and the partners' histories are.
void main() {
  /// Opens بانتظار الاعتماد of a project whose approval history [arrange] fills, then its السجل.
  Future<FakeApi> openHistory(WidgetTester tester, void Function(FakeApi api) arrange) async {
    final api = FakeApi()..addProject('مشروع A');
    arrange(api);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.approvalsKey('project-0'));
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.historyKey)));
    return api;
  }

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('each decision is a line, newest first, saying what was decided; an approval says who approved it', (tester) async {
    final api = await openHistory(tester, (api) {
      api
        ..addApprovalHistoryLine('project-0', 'rejected', amount: 300, reason: 'فاتورة مكررة')
        ..addApprovalHistoryLine('project-0', 'approved');
    });

    expect(text(tester, ScreenTitle.titleKey), 'en approvals.history');
    expect(api.historyReads.last.path, '/projects/project-0/approvals/history');
    expect(text(tester, ApprovalHistoryScreen.lineKey(3000).title), 'en history.entryRejected');
    expect(text(tester, ApprovalHistoryScreen.lineKey(2999).title), 'en history.entryApproved');
    expect(text(tester, ApprovalHistoryScreen.lineKey(2999).subtitle), contains('en history.approvedBy'));
    expect(tester.getTopLeft(find.byKey(ApprovalHistoryScreen.lineKey(3000))).dy, lessThan(tester.getTopLeft(find.byKey(ApprovalHistoryScreen.lineKey(2999))).dy));
  });

  testWidgets('a kind keeps the decisions on entries of that kind, as Approvals\' filter offers them', (tester) async {
    final api = await openHistory(tester, (api) {
      api
        ..addApprovalHistoryLine('project-0', 'approved', entryKind: 'contractorPayment')
        ..addApprovalHistoryLine('project-0', 'approved');
    });

    await openFilters(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ApprovalHistoryScreen.kindChoiceKey)));
    await act(tester, api, () => tester.tap(find.byKey(ApprovalHistoryScreen.kindKey('contractorPayment'))));

    expect(api.historyReads.last.queryParameters['kind'], 'contractorPayment');
    expect(find.byKey(ApprovalHistoryScreen.lineKey(3000)), findsOneWidget);
    expect(find.byKey(ApprovalHistoryScreen.lineKey(2999)), findsNothing);
  });

  testWidgets('R104: what is typed is asked of the API, and keeps the lines holding it', (tester) async {
    final api = await openHistory(tester, (api) {
      api
        ..addApprovalHistoryLine('project-0', 'rejected', reason: 'فاتورة مكررة')
        ..addApprovalHistoryLine('project-0', 'approved');
    });

    await searchFor(tester, api, 'مكرره');
    await tester.pump(const Duration(milliseconds: 400));
    await act(tester, api, () async {});

    expect(api.historyReads.last.queryParameters['text'], 'مكرره');
    expect(find.byKey(ApprovalHistoryScreen.lineKey(3000)), findsOneWidget);
    expect(find.byKey(ApprovalHistoryScreen.lineKey(2999)), findsNothing);
  });

  testWidgets('nothing decided yet says so', (tester) async {
    await openHistory(tester, (api) {});

    expect(text(tester, ApiListBody.emptyKey), 'en history.empty');
  });
}
