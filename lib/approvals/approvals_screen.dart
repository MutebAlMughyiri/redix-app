import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../entries/entry_kind.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../ui/refresh_button.dart';
import '../ui/refusal_snack_bar.dart';
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

  /// What a capital movement or a revenue entry is, on the card of the entry [id] (redix-api #101).
  static Key kindKey(String id) => Key('approvals.kind.$id');

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

  /// The quick reason at [index].
  static Key quickReasonKey(int index) => Key('approvals.quickReason.$index');

  /// The item of the entry [id].
  static Key itemKey(String id) => Key('approvals.item.$id');

  /// The supplier of the entry [id].
  static Key supplierKey(String id) => Key('approvals.supplier.$id');

  /// The bill number and date of the entry [id].
  static Key dateKey(String id) => Key('approvals.date.$id');

  /// Who entered the entry [id], and from which account.
  static Key enteredByKey(String id) => Key('approvals.enteredBy.$id');

  /// The notes of the entry [id].
  static Key notesKey(String id) => Key('approvals.notes.$id');

  /// The amount of the entry [id].
  static Key amountKey(String id) => Key('approvals.amount.$id');

  /// The title of the reject sheet.
  static const rejectTitleKey = Key('approvals.rejectTitle');

  /// The entry the reject sheet is about.
  static const rejectEntryKey = Key('approvals.rejectEntry');

  /// The heading over the quick reasons.
  static const quickReasonHeadingKey = Key('approvals.quickReasonHeading');

  /// The project.
  final Project project;

  /// What waits in it.
  final Approvals approvals;

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

enum _Filter {
  all,
  purchases,
  contractorPayments;

  bool keeps(PendingApproval entry) => switch (this) {
    all => true,
    purchases => entry.kind == EntryKind.purchase,
    contractorPayments => entry.kind == EntryKind.contractorPayment,
  };
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final _selected = <String>{};
  var _failed = <String, String>{};
  var _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    widget.approvals.loadOnOpen();
  }

  Future<void> _approve(Iterable<String> ids) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await widget.approvals.approve(ids);
    if (!mounted) {
      return;
    }
    if (refusal.isNotEmpty) {
      showMessage(messenger, words, refusal);
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

  /// Whether the user may decide here now: approve or reject.
  bool get _mayDecide => widget.project.mayApproveEntries;

  Widget _details(BuildContext context, PendingApproval entry) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(entry.title, key: ApprovalsScreen.itemKey(entry.id), style: theme.textTheme.titleSmall),
        if (entry.supplierName.isNotEmpty) Text(entry.supplierName, key: ApprovalsScreen.supplierKey(entry.id)),
        if (entry.kindWordKey.isNotEmpty) Text(words.text(entry.kindWordKey), key: ApprovalsScreen.kindKey(entry.id)),
        Text([if (entry.invoiceNumber.isNotEmpty) entry.invoiceNumber, formatDate(entry.date)].join(' · '), key: ApprovalsScreen.dateKey(entry.id), style: small),
        Text('${words.approvalsEnteredBy}: ${entry.authorName} · ${entry.accountName}', key: ApprovalsScreen.enteredByKey(entry.id), style: small),
        if (entry.notes.isNotEmpty) Text(entry.notes, key: ApprovalsScreen.notesKey(entry.id), style: small),
        Text(formatMoney(entry.amount), key: ApprovalsScreen.amountKey(entry.id), style: theme.textTheme.titleMedium),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final colors = Theme.of(context).colorScheme;
    final mayDecide = _mayDecide;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.approvalsTitle, subject: widget.project.name), actions: [RefreshButton(onRefresh: widget.approvals.load)]),
      bottomNavigationBar: !mayDecide || _selected.isEmpty
          ? null
          : BottomButton(buttonKey: ApprovalsScreen.approveSelectedKey, icon: Icons.done_all, label: '${words.approvalsApproveSelected} · ${_selected.length}', onPressed: () => _approve(_selected.toList())),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: widget.approvals,
            builder: (context, _) => Padding(
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
                      ChoiceChip(
                        key: key,
                        label: Text('$label · ${widget.approvals.all.where(filter.keeps).length}', key: key.label),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ApiListBody(
              list: widget.approvals,
              emptyText: words.approvalsEmpty,
              keeps: _filter.keeps,
              itemBuilder: (entry) => Card.outlined(
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
                                    onPressed: () => context.push(AttachmentScreen.pathOf(widget.project.id, entry.attachmentId, fileName: entry.fileName), extra: entry.contentType),
                                    child: Text(words.approvalsOpenFile, key: ApprovalsScreen.fileKey(entry.id).label),
                                  ),
                                if (mayDecide) ...[
                                  OutlinedButton(
                                    key: ApprovalsScreen.rejectKey(entry.id),
                                    style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                                    onPressed: () => _askToReject(entry),
                                    child: Text(words.approvalsReject, key: ApprovalsScreen.rejectKey(entry.id).label),
                                  ),
                                  FilledButton(key: ApprovalsScreen.approveKey(entry.id), onPressed: () => _approve([entry.id]), child: Text(words.approvalsApprove, key: ApprovalsScreen.approveKey(entry.id).label)),
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
