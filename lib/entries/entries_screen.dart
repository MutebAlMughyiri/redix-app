import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/confirm_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../ui/refresh_button.dart';
import '../words/words.dart';
import 'add_entry_screen.dart';
import 'entry_filter.dart';
import 'entry_row.dart';
import 'entry_tile.dart';
import 'project_entries.dart';
import 'reverse_sheet.dart';

/// A project's entries (UC-037): each person's own, or all of them, searched and filtered (redix-app #84), and what can be done to one (UC-028, UC-033, UC-035).
class EntriesScreen extends StatefulWidget {
  /// The entries of [project], in [entries], opening [openEntryId] when there is one, and ready to type a search when [startsSearching].
  const EntriesScreen({super.key, required this.project, required this.entries, this.openEntryId = '', this.startsSearching = false});

  /// True when it opens ready to type a search, as the home's search button asks.
  final bool startsSearching;

  /// The entry to open at once, as a notification asks; empty for none.
  final String openEntryId;

  /// The address of the screen.
  static const path = '/projects/:projectId/entries';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/entries';

  /// The address of the screen for the project [projectId], ready to type a search.
  static String searchPathOf(String projectId) => '/projects/$projectId/entries?search=1';

  /// The address of the screen with the entry [entryId] of the project [projectId] open.
  static String pathOfEntry(String projectId, String entryId) => '/projects/$projectId/entries?entry=$entryId';

  /// The filter showing the user's own.
  static const mineKey = Key('entries.mine');

  /// The filter showing all.
  static const allKey = Key('entries.all');

  /// The search field.
  static const searchKey = Key('entries.search');

  /// The filter of the kind [kind], `purchase` or `contractorPayment`.
  static Key kindKey(String kind) => Key('entries.kind.$kind');

  /// The filter of where an entry stands, named by its word key [wordKey].
  static Key statusFilterKey(String wordKey) => Key('entries.statusFilter.$wordKey');

  /// The filter of the period.
  static const periodKey = Key('entries.period');

  /// The button clearing the filters.
  static const clearKey = Key('entries.clear');

  /// How many entries show.
  static const foundKey = Key('entries.found');

  /// The field holding why an entry is reversed.
  static const reverseReasonKey = ReverseSheet.reasonKey;

  /// The button reversing it.
  static const reverseSendKey = ReverseSheet.sendKey;

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

  /// Opens [entry] in إضافة قيد, in its table, for a change.
  static void openForm(BuildContext context, Project project, EntryRow entry) {
    context.push(Uri(path: AddEntryScreen.pathOf(project.id), queryParameters: {'entry': entry.id, if (entry.isRejected) 'reason': entry.rejectionReason}).toString(), extra: project);
  }

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  final _filter = EntryFilter();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.entries.loadOnOpen();
    if (widget.openEntryId.isNotEmpty) {
      widget.entries.addListener(_openAsked);
    }
  }

  @override
  void dispose() {
    widget.entries.removeListener(_openAsked);
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(widget.project.startDate.year),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _filter.hasPeriod ? _filter.period : null,
    );
    if (chosen != null && mounted) {
      setState(() => _filter.period = chosen);
    }
  }

  void _clear() {
    _search.clear();
    setState(_filter.clear);
  }

  void _toggle(Set<String> chosen, String value, bool isOn) => setState(() => isOn ? chosen.add(value) : chosen.remove(value));

  /// The search field, the filters, and how many entries they keep.
  Widget _filters(Words words) {
    final found = widget.entries.all.where(_filter.keeps).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          SearchBar(
            key: EntriesScreen.searchKey,
            controller: _search,
            autoFocus: widget.startsSearching,
            hintText: words.entriesSearchHint,
            leading: const Icon(Icons.search),
            onChanged: (text) => setState(() => _filter.text = text),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(key: EntriesScreen.mineKey, label: Text(words.entriesMine), selected: _filter.onlyMine, onSelected: (_) => setState(() => _filter.onlyMine = true)),
              ChoiceChip(key: EntriesScreen.allKey, label: Text(words.entriesAll), selected: !_filter.onlyMine, onSelected: (_) => setState(() => _filter.onlyMine = false)),
              for (final MapEntry(key: kind, value: wordKey) in EntryFilter.kinds.entries)
                FilterChip(key: EntriesScreen.kindKey(kind), label: Text(words.text(wordKey)), selected: _filter.chosenKinds.contains(kind), onSelected: (isOn) => _toggle(_filter.chosenKinds, kind, isOn)),
              for (final status in EntryFilter.statuses)
                FilterChip(key: EntriesScreen.statusFilterKey(status), label: Text(words.text(status)), selected: _filter.chosenStatuses.contains(status), onSelected: (isOn) => _toggle(_filter.chosenStatuses, status, isOn)),
              FilterChip(
                key: EntriesScreen.periodKey,
                label: Text(_filter.hasPeriod ? '${words.entriesPeriod}: ${formatDate(_filter.period.start)} – ${formatDate(_filter.period.end)}' : words.entriesPeriod),
                selected: _filter.hasPeriod,
                onSelected: (_) => _pickPeriod(),
              ),
              if (_filter.isNarrowed) ActionChip(key: EntriesScreen.clearKey, label: Text(words.entriesClearFilters), onPressed: _clear),
            ],
          ),
          Text(words.entriesFound.replaceFirst('{0}', '$found'), key: EntriesScreen.foundKey, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _openAsked() {
    if (widget.entries.isLoading) {
      return;
    }
    widget.entries.removeListener(_openAsked);
    for (final entry in widget.entries.all.where((entry) => entry.id == widget.openEntryId)) {
      EntriesScreen.openActions(context, widget.project, widget.entries, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.entriesTitle, subject: widget.project.name), actions: [RefreshButton(onRefresh: widget.entries.load)]),
      body: Column(
        children: [
          ListenableBuilder(listenable: widget.entries, builder: (_, _) => _filters(words)),
          Expanded(
            child: ApiListBody(
              list: widget.entries,
              emptyText: words.entriesEmpty,
              itemBuilder: (entry) => _filter.keeps(entry)
                  ? EntryTile(entry: entry, onTap: () => EntriesScreen.openActions(context, widget.project, widget.entries, entry))
                  : const SizedBox.shrink(),
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

  /// Whether [permission] lets the user act on this entry now: it is not approved, and it is theirs and not waiting, or they handle others' entries.
  bool _may(Permission permission) => !project.isFinished && !entry.isApproved && project.may(permission) && (entry.isMine ? !entry.isPending || project.may(Permission.manageAnyEntry) : project.may(Permission.manageAnyEntry));

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
    ReverseSheet.show(context, (reason) => entries.reverse(entry, reason));
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
          if (_may(Permission.recordEntries)) ...[
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
          ],
          if (_may(Permission.deleteEntries)) TextButton(key: EntriesScreen.deleteKey, onPressed: () => _askToDelete(context), child: Text(words.entriesDelete)),
          if (mayReverse) OutlinedButton(key: EntriesScreen.reverseKey, onPressed: () => _askToReverse(context), child: Text(words.entriesReverse)),
        ],
      ),
    );
  }
}
