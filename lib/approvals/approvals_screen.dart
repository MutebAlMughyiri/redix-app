// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../entries/entry_status.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../entries/entry_kind.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/part_keys.dart';
import '../ui/reason_sheet.dart';
import '../ui/screen_title.dart';
import '../ui/messages.dart';
import '../ui/notice_box.dart';
import '../words/words.dart';
import 'approvals.dart';
import 'pending_approval.dart';
import 'reject_sheet.dart';
import '../ui/app_color.dart';
import '../format/parts_line.dart';
import '../ui/refusal_text.dart';
import '../ui/act_once.dart';
import '../words/word_fill.dart';
import '../ui/filter_line.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import 'approval_history_screen.dart';

/// Finance's inbox (UC-031, UC-032): what waits, oldest first, to approve one at a time or many at once, or to reject saying why.
class ApprovalsScreen extends StatefulWidget {
  /// The inbox of [project], decided through [approvals].
  const ApprovalsScreen({super.key, required this.project, required this.approvals, this.focusEntryId = ''});

  /// The entry a shared link opened, shown alone until everything is asked for (redix-app #83); empty for everything.
  final String focusEntryId;

  /// Approvals of the project [projectId] on the entry [entryId] alone.
  static String pathOfEntry(String projectId, String entryId) => Uri(path: pathOf(projectId), queryParameters: {'entry': entryId}).toString();

  /// The button showing everything waiting, when one entry is shown alone.
  static const showAllKey = Key('approvals.showAll');

  /// The address of the screen.
  static const path = '/projects/:projectId/approvals';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/approvals';

  /// The filter showing everything.
  static const allKey = Key('approvals.all');

  /// The choice among the filters, folded under the search line (redix-app #104).
  static const filterChoiceKey = Key('approvals.filterChoice');

  /// What a capital movement or a revenue entry is, on the card of the entry [id] (redix-api #101).
  static Key kindKey(String id) => Key('approvals.kind.$id');

  /// The filter showing purchases.
  static const purchasesKey = Key('approvals.purchases');

  /// The filter showing contractor payments.
  static const contractorPaymentsKey = Key('approvals.contractorPayments');

  /// السجل in the title bar: what was approved and rejected (Muteb, 12 Nov 2026).
  static const historyKey = Key('approvals.history');

  /// The button approving what is selected.
  static const approveSelectedKey = Key('approvals.approveSelected');

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
  static Key quickReasonKey(int index) => ReasonSheet.quickReasonKey(index);

  /// The item of the entry [id].
  static Key itemKey(String id) => Key('approvals.item.$id');

  /// The supplier of the entry [id].
  static Key supplierKey(String id) => Key('approvals.supplier.$id');

  /// The line under the entry [id]'s name: its «قيد 312», an older bill's number and its date (redix-api #128).
  static Key detailsKey(String id) => Key('approvals.details.$id');

  /// Who entered the entry [id], and from which account.
  static Key enteredByKey(String id) => Key('approvals.enteredBy.$id');

  /// The note on the entry [id] saying its account does not hold enough for it (redix-app #89, R5).
  static Key shortKey(String id) => Key('approvals.short.$id');

  /// «الوصف» of the entry [id] (redix-api #129).
  static Key descriptionKey(String id) => Key('approvals.description.$id');

  /// The amount of the entry [id].
  static Key amountKey(String id) => Key('approvals.amount.$id');

  /// The project.
  final Project project;

  /// What waits in it.
  final Approvals approvals;

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

enum _Filter {
  all(ApprovalsScreen.allKey, 'approvals.all'),
  purchases(ApprovalsScreen.purchasesKey, 'approvals.purchases'),
  contractorPayments(ApprovalsScreen.contractorPaymentsKey, 'approvals.contractorPayments');

  const _Filter(this.key, this.wordKey);

  /// Its segment's key.
  final Key key;

  /// The key of the word that names it.
  final String wordKey;

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
  late var _focus = widget.focusEntryId;

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

  void _askToReject(PendingApproval entry) => RejectSheet.show(context, entry, widget.approvals);

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
        Text(partsLine([entry.numberIn(words), entry.invoiceNumber, formatDate(entry.date)]), key: ApprovalsScreen.detailsKey(entry.id), style: small),
        Text('${words.approvalsEnteredBy}: ${entry.authorName} · ${entry.accountName}', key: ApprovalsScreen.enteredByKey(entry.id), style: small),
        if (entry.accountShortBy > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: NoticeBox(
              key: ApprovalsScreen.shortKey(entry.id),
              text: words.approvalsAccountShort.fill([entry.accountName, formatMoney(entry.accountBalance), formatMoney(entry.accountWaiting), formatMoney(entry.accountShortBy)]),
              textKey: ApprovalsScreen.shortKey(entry.id).label,
              style: small ?? const TextStyle(),
            ),
          ),
        if (entry.description.isNotEmpty) Text(entry.description, key: ApprovalsScreen.descriptionKey(entry.id), style: small),
        Text(formatMoney(entry.amount), key: ApprovalsScreen.amountKey(entry.id), style: theme.textTheme.titleMedium),
      ],
    );
  }

  Widget _card(PendingApproval entry, bool mayDecide, Words words) => Card.outlined(
    key: ApprovalsScreen.cardKey(entry.id),
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: EntryStatus.pendingApproval.sideIn(context)),
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
            child: refusalText(context, words.text(_failed[entry.id]!), ApprovalsScreen.failedKey(entry.id)),
          ),
          ActOnce(builder: (once) => Wrap(
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
                  style: OutlinedButton.styleFrom(foregroundColor: AppColor.refusal.of(context)),
                  onPressed: once(() => _askToReject(entry)),
                  child: Text(words.approvalsReject, key: ApprovalsScreen.rejectKey(entry.id).label),
                ),
                FilledButton(key: ApprovalsScreen.approveKey(entry.id), onPressed: once(() => _approve([entry.id])), child: Text(words.approvalsApprove, key: ApprovalsScreen.approveKey(entry.id).label)),
              ],
            ],
          )),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final mayDecide = _mayDecide;
    return SearchScope(
      child: Scaffold(
        appBar: AppBar(
          title: ScreenTitle(words.approvalsTitle, subject: widget.project.name),
          actions: [
            SearchIcons.andFilters(filtersInUse: _filter != _Filter.all),
            IconButton(
              key: ApprovalsScreen.historyKey,
              tooltip: words.approvalsHistory,
              icon: Icon(Icons.history, key: ApprovalsScreen.historyKey.icon),
              onPressed: () => context.push(ApprovalHistoryScreen.pathOf(widget.project.id), extra: widget.project),
            ),
          ],
        ),
        bottomNavigationBar: !mayDecide || _selected.isEmpty
            ? null
            : BottomButton(buttonKey: ApprovalsScreen.approveSelectedKey, icon: Icons.done_all, label: '${words.approvalsApproveSelected} · ${_selected.length}', onPressed: () => _approve(_selected.toList())),
        body: Column(
          children: [
            if (_focus.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(key: ApprovalsScreen.showAllKey, onPressed: () => setState(() => _focus = ''), child: Text(words.approvalsShowAll, key: ApprovalsScreen.showAllKey.label)),
              ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.approvals,
                builder: (context, _) => ApiListBody<PendingApproval>(
                  list: widget.approvals,
                  emptyText: words.approvalsEmpty,
                  keeps: (entry) => (_focus.isEmpty || entry.id == _focus) && _filter.keeps(entry),
                  search: ListSearch(
                    hint: words.commonSearchIn.fill([words.approvalsTitle]),
                    textOf: (entry) => partsLine([entry.itemName, entry.supplierName, entry.partnerName, entry.authorName, entry.accountName, entry.invoiceNumber, entry.description, searchableAmount(entry.amount)]),
                    filters: [
                      FilterLine.segmented(
                        key: ApprovalsScreen.filterChoiceKey,
                        values: _Filter.values,
                        selected: _filter,
                        labelOf: (filter) => '${words.text(filter.wordKey)} · ${widget.approvals.all.where(filter.keeps).length}',
                        keyOf: (filter) => filter.key,
                        onChanged: (filter) => setState(() => _filter = filter),
                      ),
                    ],
                  ),
                  itemBuilder: (entry) => _card(entry, mayDecide, words),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
