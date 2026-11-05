import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/attachments/attachment_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openInbox(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance, String status = 'running'}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, status: status);
    arrange(api);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.approvalsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.approvalsKey('project-0'))));
    return api;
  }

  testWidgets('only whoever decides entries has a way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field);
    await pumpRedix(tester, api, stored: {'session': keptSession});

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

    expect(find.byKey(HomeScreen.approvalsKey('project-0')), findsNothing);
  });

  testWidgets('AC-18.1: what waits shows what Finance needs to decide, in the order the API gives', (tester) async {
    await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending(amount: 500, vat: 0, withoutInvoiceReason: 'شراء من السوق', attachmentId: '');
    });

    expect(tester.getTopLeft(find.byKey(ApprovalsScreen.cardKey('entry-0'))).dy, lessThan(tester.getTopLeft(find.byKey(ApprovalsScreen.cardKey('entry-1'))).dy));
    expect(find.text('شركة البواني'), findsNWidgets(2));
    expect(find.text('1,150.00'), findsOneWidget);
    expect(find.text('en approvals.includingVat 150.00'), findsOneWidget);
    expect(find.text('en approvals.withoutInvoice: شراء من السوق'), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.fileKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.fileKey('entry-1')), findsNothing);
  });

  testWidgets('AC-49.3: the inbox shows what an attached invoice says differently', (tester) async {
    await openInbox(tester, (api) {
      api
        ..addPending(amount: 100, invoiceTotal: 150, sellerVatNumber: '300000000000099', supplierVatNumber: '300000000000003')
        ..addPending();
    });

    expect(find.byKey(ApprovalsScreen.invoiceTotalKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.sellerDiffersKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.invoiceTotalKey('entry-1')), findsNothing);
    expect(find.byKey(ApprovalsScreen.sellerDiffersKey('entry-1')), findsNothing);
  });

  testWidgets('nothing waiting says so', (tester) async {
    await openInbox(tester, (_) {});

    expect(find.text('en approvals.empty'), findsOneWidget);
  });

  testWidgets('a filter shows purchases or contractor payments alone', (tester) async {
    final api = await openInbox(tester, (api) {
      api
        ..addPending()
        ..addPending(kind: 'contractorPayment');
    });

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.contractorPaymentsKey)));
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.purchasesKey)));
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
    expect(find.byKey(ApprovalsScreen.cardKey('entry-1')), findsNothing);
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
    expect(find.text('en approvals.approveSelected · 2'), findsOneWidget);

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
        ..approvalFailures['entry-1'] = 'originalNotApproved';
    });
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.selectKey('entry-0'))));
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.selectKey('entry-1'))));

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.approveSelectedKey)));

    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsNothing);
    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.failedKey('entry-1'))).data, 'en approvals.originalNotApproved');
  });

  testWidgets('AC-19.1: rejecting needs a reason, and the refusal shows on the sheet', (tester) async {
    final api = await openInbox(tester, (api) => api.addPending());
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.rejectKey('entry-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.rejectSendKey)));

    expect(tester.widget<Text>(find.byKey(ApprovalsScreen.rejectMessageKey)).data, 'en approvals.reasonRequired');
    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
  });

  testWidgets('a quick reason fills the field, and rejecting sends it and closes', (tester) async {
    final api = await openInbox(tester, (api) => api.addPending());
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.rejectKey('entry-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.quickReasonKey(1))));
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.rejectSendKey)));

    expect(api.sentRejections.single, ('entry-0', 'en approvals.reasonAmount'));
    expect(find.byKey(ApprovalsScreen.rejectSendKey), findsNothing);
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
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('a PDF is offered to the phone, and a file that cannot be read says so', (tester) async {
    final api = await openInbox(tester, (api) {
      api
        ..addPending(attachmentId: 'attachment-pdf', contentType: 'application/pdf')
        ..addPending(attachmentId: 'attachment-gone');
    });

    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.fileKey('entry-0'))));
    expect(find.byKey(AttachmentScreen.openPdfKey), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byKey(ApprovalsScreen.fileKey('entry-1'))));
    expect(find.byKey(AttachmentScreen.failedKey), findsOneWidget);
  });
}
