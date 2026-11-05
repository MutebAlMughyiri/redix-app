import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'approvals.dart';
import 'pending_approval.dart';
import 'reject_sheet.dart';

/// Finance's inbox (UC-031, UC-032): what waits, oldest first, to approve one at a time or many at once, or to reject saying why.
class ApprovalsScreen extends StatefulWidget {
  /// The inbox of [project], decided through [approvals].
  const ApprovalsScreen({super.key, required this.project, required this.approvals});

  /// The address of the screen.
  static const path = '/projects/:projectId/approvals';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/approvals';

  /// The filter showing everything.
  static const allKey = Key('approvals.all');

  /// The filter showing purchases.
  static const purchasesKey = Key('approvals.purchases');

  /// The filter showing contractor payments.
  static const contractorPaymentsKey = Key('approvals.contractorPayments');

  /// The button approving what is selected.
  static const approveSelectedKey = Key('approvals.approveSelected');

  /// The field holding why an entry is rejected.
  static const reasonKey = Key('approvals.reason');

  /// The button rejecting the entry.
  static const rejectSendKey = Key('approvals.rejectSend');

  /// The line saying why a rejection was refused.
  static const rejectMessageKey = Key('approvals.rejectMessage');

  /// The card of the entry [id].
  static Key cardKey(String id) => Key('approvals.card.$id');

  /// The box selecting the entry [id].
  static Key selectKey(String id) => Key('approvals.select.$id');

  /// The button approving the entry [id].
  static Key approveKey(String id) => Key('approvals.approve.$id');

  /// The button rejecting the entry [id].
  static Key rejectKey(String id) => Key('approvals.reject.$id');

  /// The button opening the file of the entry [id].
  static Key fileKey(String id) => Key('approvals.file.$id');

  /// The line saying why the entry [id] could not be approved.
  static Key failedKey(String id) => Key('approvals.failed.$id');

  /// The invoice's total of the entry [id], when it differs from what was paid.
  static Key invoiceTotalKey(String id) => Key('approvals.invoiceTotal.$id');

  /// The line saying the invoice of the entry [id] is from another seller.
  static Key sellerDiffersKey(String id) => Key('approvals.sellerDiffers.$id');

  /// The quick reason at [index].
  static Key quickReasonKey(int index) => Key('approvals.quickReason.$index');

  /// The project.
  final Project project;

  /// What waits in it.
  final Approvals approvals;

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

enum _Filter { all, purchases, contractorPayments }

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final _selected = <String>{};
  var _failed = <String, String>{};
  var _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    widget.approvals.loadOnOpen();
  }

  bool _isShown(PendingApproval entry) => switch (_filter) {
    _Filter.all => true,
    _Filter.purchases => !entry.isContractorPayment,
    _Filter.contractorPayments => entry.isContractorPayment,
  };

  Future<void> _approve(Iterable<String> ids) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await widget.approvals.approve(ids);
    if (!mounted) {
      return;
    }
    if (refusal.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(words.text(refusal))));
      return;
    }
    setState(() {
      _failed = widget.approvals.failed;
      _selected.removeAll(ids);
    });
  }

  void _askToReject(PendingApproval entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => RejectSheet(entry: entry, approvals: widget.approvals),
    );
  }

  Widget _details(BuildContext context, PendingApproval entry) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(entry.itemName, style: theme.textTheme.titleSmall),
        if (entry.supplierName.isNotEmpty) Text(entry.supplierName),
        Text([if (entry.invoiceNumber.isNotEmpty) entry.invoiceNumber, formatDate(entry.date), if (entry.unitName.isNotEmpty) entry.unitName].join(' · '), style: small),
        Text('${words.approvalsEnteredBy}: ${entry.authorName} · ${entry.accountName}', style: small),
        if (entry.withoutInvoiceReason.isNotEmpty) Text('${words.approvalsWithoutInvoice}: ${entry.withoutInvoiceReason}', style: small),
        if (entry.notes.isNotEmpty) Text(entry.notes, style: small),
        Text(formatMoney(entry.amount), style: theme.textTheme.titleMedium),
        if (entry.vat != 0) Text('${words.approvalsIncludingVat} ${formatMoney(entry.vat)}', style: small),
        if (entry.totalDiffers) Text('${words.approvalsInvoiceTotal}: ${formatMoney(entry.invoiceTotal)}', key: ApprovalsScreen.invoiceTotalKey(entry.id), style: small),
        if (entry.sellerDiffers) Text(words.approvalsSellerDiffers, key: ApprovalsScreen.sellerDiffersKey(entry.id), style: TextStyle(color: theme.colorScheme.error)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final colors = Theme.of(context).colorScheme;
    final mayDecide = !widget.project.isFinished;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.approvalsTitle, subject: widget.project.name)),
      bottomNavigationBar: !mayDecide || _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton(key: ApprovalsScreen.approveSelectedKey, onPressed: () => _approve(_selected.toList()), child: Text('${words.approvalsApproveSelected} · ${_selected.length}')),
              ),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final (filter, key, label) in [
                    (_Filter.all, ApprovalsScreen.allKey, words.approvalsAll),
                    (_Filter.purchases, ApprovalsScreen.purchasesKey, words.approvalsPurchases),
                    (_Filter.contractorPayments, ApprovalsScreen.contractorPaymentsKey, words.approvalsContractorPayments),
                  ])
                    ChoiceChip(key: key, label: Text(label), selected: _filter == filter, onSelected: (_) => setState(() => _filter = filter)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ApiListBody(
              list: widget.approvals,
              emptyText: words.approvalsEmpty,
              itemBuilder: (entry) => !_isShown(entry)
                  ? const SizedBox.shrink()
                  : Card.outlined(
                      key: ApprovalsScreen.cardKey(entry.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  key: ApprovalsScreen.selectKey(entry.id),
                                  value: _selected.contains(entry.id),
                                  onChanged: mayDecide ? (on) => setState(() => on == true ? _selected.add(entry.id) : _selected.remove(entry.id)) : null,
                                ),
                                Expanded(child: _details(context, entry)),
                              ],
                            ),
                            if (_failed.containsKey(entry.id)) Padding(
                              padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
                              child: Text(words.text(_failed[entry.id]!), key: ApprovalsScreen.failedKey(entry.id), style: TextStyle(color: colors.error)),
                            ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              children: [
                                if (entry.hasFile)
                                  TextButton(
                                    key: ApprovalsScreen.fileKey(entry.id),
                                    onPressed: () => context.push(AttachmentScreen.pathOf(widget.project.id, entry.attachmentId), extra: entry.contentType),
                                    child: Text(words.approvalsOpenFile),
                                  ),
                                if (mayDecide) ...[
                                  OutlinedButton(
                                    key: ApprovalsScreen.rejectKey(entry.id),
                                    style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                                    onPressed: () => _askToReject(entry),
                                    child: Text(words.approvalsReject),
                                  ),
                                  FilledButton(key: ApprovalsScreen.approveKey(entry.id), onPressed: () => _approve([entry.id]), child: Text(words.approvalsApprove)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
