import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/permission.dart';
import '../contractor_payments/contractor_payment_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/confirm_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'entry_row.dart';
import 'entry_tile.dart';
import 'project_entries.dart';

/// A project's entries (UC-037): each person's own, or all of them, and what can be done to one (UC-028, UC-033, UC-035).
class EntriesScreen extends StatefulWidget {
  /// The entries of [project], in [entries].
  const EntriesScreen({super.key, required this.project, required this.entries});

  /// The address of the screen.
  static const path = '/projects/:projectId/entries';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/entries';

  /// The filter showing the user's own.
  static const mineKey = Key('entries.mine');

  /// The filter showing all.
  static const allKey = Key('entries.all');

  /// The field holding why an entry is reversed.
  static const reverseReasonKey = Key('entries.reverseReason');

  /// The button reversing it.
  static const reverseSendKey = Key('entries.reverseSend');

  /// The row of the entry [id].
  static Key rowKey(String id) => Key('entries.row.$id');

  /// Where the entry [id] stands.
  static Key statusKey(String id) => Key('entries.status.$id');

  /// Why the entry [id] was rejected.
  static Key reasonKey(String id) => Key('entries.reason.$id');

  /// The button fixing or changing the open entry.
  static const editKey = Key('entries.edit');

  /// The button sending the open entry.
  static const sendKey = Key('entries.send');

  /// The button deleting the open entry.
  static const deleteKey = Key('entries.delete');

  /// The button reversing the open entry.
  static const reverseKey = Key('entries.reverse');

  /// The project.
  final Project project;

  /// Its entries.
  final ProjectEntries entries;

  /// Opens what can be done to [entry].
  static void openActions(BuildContext context, Project project, ProjectEntries entries, EntryRow entry) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, useSafeArea: true, builder: (_) => _EntryActions(project: project, entries: entries, entry: entry));
  }

  /// Opens [entry] in its form, for a change.
  static void openForm(BuildContext context, Project project, EntryRow entry) {
    final form = entry.isContractorPayment ? ContractorPaymentScreen.pathOf(project.id) : AddExpenseScreen.pathOf(project.id);
    context.push(Uri(path: form, queryParameters: {'entry': entry.id, if (entry.isRejected) 'reason': entry.rejectionReason}).toString(), extra: project);
  }

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  var _onlyMine = true;

  @override
  void initState() {
    super.initState();
    widget.entries.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.entriesTitle, subject: widget.project.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(key: EntriesScreen.mineKey, label: Text(words.entriesMine), selected: _onlyMine, onSelected: (_) => setState(() => _onlyMine = true)),
                  ChoiceChip(key: EntriesScreen.allKey, label: Text(words.entriesAll), selected: !_onlyMine, onSelected: (_) => setState(() => _onlyMine = false)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ApiListBody(
              list: widget.entries,
              emptyText: words.entriesEmpty,
              itemBuilder: (entry) => _onlyMine && !entry.isMine
                  ? const SizedBox.shrink()
                  : EntryTile(entry: entry, onTap: () => EntriesScreen.openActions(context, widget.project, widget.entries, entry)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryActions extends StatelessWidget {
  const _EntryActions({required this.project, required this.entries, required this.entry});

  final Project project;
  final ProjectEntries entries;
  final EntryRow entry;

  bool get _mayChange => !project.isFinished && !entry.isApproved && project.may(Permission.recordEntries) && (entry.isMine ? !entry.isPending || project.may(Permission.manageAnyEntry) : project.may(Permission.manageAnyEntry));

  void _askToDelete(BuildContext context) {
    final words = Words.of(context);
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (dialog) => ConfirmDialog(
        title: words.entriesDeleteQuestion,
        subject: entry.itemName,
        explanation: words.entriesDeleteExplain,
        confirmLabel: words.entriesDelete,
        onConfirm: () {
          navigator.pop();
          showRefusalOf(context, entries.delete(entry));
        },
      ),
    );
  }

  void _askToReverse(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => _ReverseSheet(entries: entries, entry: entry));
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final mayReverse = !project.isFinished && entry.isApproved && !entry.isReversed && project.may(Permission.approveEntries);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          EntryTile(entry: entry, onTap: () {}),
          if (_mayChange) ...[
            FilledButton(
              key: EntriesScreen.editKey,
              onPressed: () {
                Navigator.of(context).pop();
                EntriesScreen.openForm(context, project, entry);
              },
              child: Text(entry.isRejected ? words.entriesFix : words.entriesEdit),
            ),
            if (entry.isDraft)
              OutlinedButton(
                key: EntriesScreen.sendKey,
                onPressed: () {
                  Navigator.of(context).pop();
                  showRefusalOf(context, entries.send(entry));
                },
                child: Text(words.entriesSend),
              ),
            TextButton(key: EntriesScreen.deleteKey, onPressed: () => _askToDelete(context), child: Text(words.entriesDelete)),
          ],
          if (mayReverse) OutlinedButton(key: EntriesScreen.reverseKey, onPressed: () => _askToReverse(context), child: Text(words.entriesReverse)),
        ],
      ),
    );
  }
}

class _ReverseSheet extends StatefulWidget {
  const _ReverseSheet({required this.entries, required this.entry});

  final ProjectEntries entries;
  final EntryRow entry;

  @override
  State<_ReverseSheet> createState() => _ReverseSheetState();
}

class _ReverseSheetState extends State<_ReverseSheet> {
  final _reason = TextEditingController();
  var _message = '';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reverse() async {
    final refusal = await widget.entries.reverse(widget.entry, _reason.text);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _message = refusal);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(words.entriesReverseTitle, style: theme.textTheme.titleLarge),
            Text(words.entriesReverseExplain),
            TextField(
              key: EntriesScreen.reverseReasonKey,
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(labelText: words.entriesReverseReason, border: const OutlineInputBorder()),
            ),
            if (_message.isNotEmpty) Text(words.text(_message), style: TextStyle(color: theme.colorScheme.error)),
            FilledButton(key: EntriesScreen.reverseSendKey, onPressed: _reverse, child: Text(words.entriesReverse)),
          ],
        ),
      ),
    );
  }
}
