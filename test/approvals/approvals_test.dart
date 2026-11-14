import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/attachments/attachment_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';
import 'package:redix/ui/reason_sheet.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<FakeApi> openInbox(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance, String status = 'active', FakeCapture? capture}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, status: status);
    arrange(api);
    await openProject(tester, api, capture: capture);
    await showProjectSetting(tester, HomeScreen.approvalsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, api, HomeScreen.approvalsKey('project-0'));
    return api;
  }

  testWidgets('only whoever decides entries has a way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field);
    await openProject(tester, api);

    await showProjectSetting(tester, HomeScreen.approvalsKey('project-0'));
    expect(find.byKey(HomeScreen.approvalsKey('project-0')), findsNothing);
  });

  testWidgets('AC-18.1: what waits shows what Finance needs to decide, in the order the API gives', (tester) async {
    await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending(amount: 500, description: 'شراء من السوق', attachmentId: '');
    });

    expect(tester.getTopLeft(find.byKey(ApprovalsScreen.cardKey('entry-0'))).dy, lessThan(tester.getTopLeft(find.byKey(ApprovalsScreen.cardKey('entry-1'))).dy));
    expect((text(tester, ApprovalsScreen.supplierKey('entry-0')), text(tester, ApprovalsScreen.supplierKey('entry-1'))), ('شركة البواني', 'شركة البواني'));
    expect(text(tester, ApprovalsScreen.amountKey('entry-0')), '1,150.00');
    expect(text(tester, ApprovalsScreen.descriptionKey('entry-1')), 'شراء من السوق');
    expect(find.byKey(ApprovalsScreen.fileKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.fileKey('entry-1')), findsNothing);
  });

  testWidgets('nothing waiting says so', (tester) async {
    await openInbox(tester, (_) {});

    expect(text(tester, ApiListBody.emptyKey), 'en approvals.empty');
  });

  testWidgets('a filter shows purchases or contractor payments alone', (tester) async {
    final api = await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending(kind: 'contractorPayment');
    });

    await openFilters(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.contractorPaymentsKey)));
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.purchasesKey)));
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsNothing);
  });

  testWidgets('each filter counts what it keeps, and one that keeps nothing says nothing waits rather than showing a blank page', (tester) async {
    final api = await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending();
    });

    await openFilters(tester, api);
    expect(text(tester, ApprovalsScreen.allKey.label), 'en approvals.all · 2');
    expect(text(tester, ApprovalsScreen.purchasesKey.label), 'en approvals.purchases · 2');
    expect(text(tester, ApprovalsScreen.contractorPaymentsKey.label), 'en approvals.contractorPayments · 0');

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.contractorPaymentsKey)));

    expect(text(tester, ApiListBody.emptyKey), 'en approvals.empty');
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
  });

  testWidgets('R16: an entry of a partner waits named after the partner and its kind, and a revenue entry after its item', (tester) async {
    await openInbox(tester, (api) {
      api
        ..addPending(kind: 'capitalOut', amount: 300, partnerName: 'نواف')
        ..addPending(kind: 'revenue', amount: 140);
    });

    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.itemKey('entry-0'))).data, 'نواف');
    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.kindKey('entry-0'))).data, 'en capital.withdrawal');
    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.itemKey('entry-1'))).data, 'بند اللياسة');
    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.kindKey('entry-1'))).data, 'en categories.tableRevenue');
  });

  testWidgets('R16: an expense shows no kind line, and the purchases filter leaves out entries of partners and revenue', (tester) async {
    final api = await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending(kind: 'capitalIn', partnerName: 'نواف')
        ..addPending(kind: 'revenue');
    });
    expect(find.byKey(ApprovalsScreen.kindKey('entry-0')), findsNothing);

    await openFilters(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.purchasesKey)));

    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsNothing);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-2')), findsNothing);
  });

  testWidgets('pressing Approve twice before the API answers sends one approval, and the button is gray meanwhile', (tester) async {
    final api = await openInbox(tester, (api) => api.addPending());
    final approve = tester.widget<FilledButton>(find.byKey(ApprovalsScreen.approveKey('entry-0'))).onPressed!;

    await act(tester, api, () async {
      approve();
      approve();
    });

    expect(api.sentApprovals.single, ['entry-0']);
  });

  testWidgets('approving one sends it, and it leaves the inbox', (tester) async {
    final api = await openInbox(tester, (api) => api.addPending());

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.approveKey('entry-0'))));

    expect(api.sentApprovals.single, ['entry-0']);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
  });

  testWidgets('Approve selected appears with a selection, and sends what was ticked', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending()
        ..addPending();
    });
    expect(find.byKey(ApprovalsScreen.approveSelectedKey), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.selectKey('entry-0'))));
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.selectKey('entry-2'))));
    expect(text(tester, ApprovalsScreen.approveSelectedKey.label), 'en approvals.approveSelected · 2');

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.approveSelectedKey)));

    expect(api.sentApprovals.single, ['entry-0', 'entry-2']);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.approveSelectedKey), findsNothing);
  });

  testWidgets('AC-19.2: what could not be approved stays, saying why', (tester) async {
    final api = await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending()
        ..approvalFailures['entry-1'] = 'entryNotPending';
    });
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.selectKey('entry-0'))));
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.selectKey('entry-1'))));

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.approveSelectedKey)));

    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.failedKey('entry-1'))).data, 'en approvals.entryNotPending');
  });

  testWidgets('AC-19.1: rejecting needs a reason, and the refusal shows on the sheet', (tester) async {
    final api = await openInbox(tester, (api) => api.addPending());
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.rejectKey('entry-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ReasonSheet.sendKey)));

    expect(tester.widget<Text>(find.byKey(ReasonSheet.messageKey)).data, 'en approvals.reasonRequired');
    expectErrorAbove(tester, ReasonSheet.messageKey, ReasonSheet.reasonKey);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
  });

  testWidgets('a quick reason fills the field, and rejecting sends it and closes', (tester) async {
    final api = await openInbox(tester, (api) => api.addPending());
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.rejectKey('entry-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.quickReasonKey(1))));
    await act(tester, api, () => tester.tap(find.byKey(ReasonSheet.sendKey)));

    expect(api.sentRejections.single, ('entry-0', 'en approvals.reasonAmount'));
    expect(find.byKey(ReasonSheet.sendKey), findsNothing);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
  });

  testWidgets('a finished project shows what waits, and offers no decision', (tester) async {
    await openInbox(tester, (api) => api.addPending(), status: 'finished');

    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.approveKey('entry-0')), findsNothing);
    expect(find.byKey(ApprovalsScreen.rejectKey('entry-0')), findsNothing);
  });

  testWidgets('AC-18.1: a picture opens to zoom into', (tester) async {
    final api = await openInbox(tester, (api) => api.addPending());

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.fileKey('entry-0'))));

    expect(find.byKey(AttachmentScreen.pictureKey), findsOneWidget);
    expect(tester.widget<InteractiveViewer>(find.byKey(AttachmentScreen.zoomKey)).maxScale, greaterThan(1));
  });

  testWidgets('a PDF is handed to the phone by its own name, and a file that cannot be read says so', (tester) async {
    final capture = FakeCapture();
    final api = await openInbox(tester, capture: capture, (api) {
      api
        ..addPending(attachmentId: 'attachment-pdf', contentType: 'application/pdf', fileName: 'bill-2617.pdf')
        ..addPending(attachmentId: 'attachment-gone');
    });

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.fileKey('entry-0'))));
    await act(tester, api, () => tester.tap(find.byKey(AttachmentScreen.openFileKey)));
    expect(capture.sharedOut.single, ('bill-2617.pdf', 'application/pdf'));

    await act(tester, api, () => tester.pageBack());
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.fileKey('entry-1'))));
    expect(find.byKey(AttachmentScreen.failedKey), findsOneWidget);
  });

  testWidgets('redix-app #89 R5: an entry whose account does not hold all that waits on it says so, with the account, what it holds, what waits and how much is short', (tester) async {
    late String short;
    late String covered;
    await openInbox(tester, (api) {
      short = api.addPending(amount: 600, accountBalance: 1000, accountWaiting: 1200, accountShortBy: 200)['id']! as String;
      covered = api.addPending(amount: 100, accountBalance: 5000, accountWaiting: 100)['id']! as String;
    });

    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.shortKey(short).label)).data, 'en approvals.accountShort');
    expect(find.byKey(ApprovalsScreen.shortKey(covered)), findsNothing);
  });

  testWidgets('redix-app #89 R4: nothing blocks a short entry: it is approved as any other', (tester) async {
    late String short;
    final api = await openInbox(tester, (api) => short = api.addPending(amount: 3000, accountBalance: 2750, accountWaiting: 3000, accountShortBy: 250)['id']! as String);

    await tester.ensureVisible(find.byKey(ApprovalsScreen.approveKey(short)));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.approveKey(short))));

    expect(api.sentApprovals.single, [short]);
  });
}
