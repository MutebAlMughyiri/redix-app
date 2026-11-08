import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../ui/swipe_to_remove.dart';
import '../ui/refresh_button.dart';
import '../words/words.dart';
import 'add_entry_screen.dart';
import 'entry_filter.dart';
import 'entry_kind.dart';
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

  /// The line saying an entry is removed by a swipe (redix-api #102).
  static const swipeHintKey = Key('entries.swipeHint');

  /// The button reversing the open entry.
  static const reverseKey = Key('entries.reverse');

  /// Who supplied the entry [id], when, and who entered it.
  static Key detailsKey(String id) => Key('entries.details.$id');

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

  void _toggle<T>(Set<T> chosen, T value, bool isOn) => setState(() => isOn ? chosen.add(value) : chosen.remove(value));

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
            leading: Icon(Icons.search, key: EntriesScreen.searchKey.icon),
            onChanged: (text) => setState(() => _filter.text = text),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(key: EntriesScreen.mineKey, label: Text(words.entriesMine, key: EntriesScreen.mineKey.label), selected: _filter.onlyMine, onSelected: (_) => setState(() => _filter.onlyMine = true)),
              ChoiceChip(key: EntriesScreen.allKey, label: Text(words.entriesAll, key: EntriesScreen.allKey.label), selected: !_filter.onlyMine, onSelected: (_) => setState(() => _filter.onlyMine = false)),
              for (final kind in EntryKind.values)
                FilterChip(key: EntriesScreen.kindKey(kind.name), label: Text(words.text(kind.wordKey), key: EntriesScreen.kindKey(kind.name).label), selected: _filter.chosenKinds.contains(kind), onSelected: (isOn) => _toggle(_filter.chosenKinds, kind, isOn)),
              for (final status in EntryFilter.statuses)
                FilterChip(key: EntriesScreen.statusFilterKey(status), label: Text(words.text(status), key: EntriesScreen.statusFilterKey(status).label), selected: _filter.chosenStatuses.contains(status), onSelected: (isOn) => _toggle(_filter.chosenStatuses, status, isOn)),
              FilterChip(
                key: EntriesScreen.periodKey,
                label: Text(_filter.hasPeriod ? '${words.entriesPeriod}: ${formatDate(_filter.period.start)} – ${formatDate(_filter.period.end)}' : words.entriesPeriod, key: EntriesScreen.periodKey.label),
                selected: _filter.hasPeriod,
                onSelected: (_) => _pickPeriod(),
              ),
              if (_filter.isNarrowed) ActionChip(key: EntriesScreen.clearKey, label: Text(words.entriesClearFilters, key: EntriesScreen.clearKey.label), onPressed: _clear),
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
          if (widget.project.may(Permission.deleteEntries)) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SwipeHint(key: EntriesScreen.swipeHintKey)),
          Expanded(
            child: ApiListBody(
              list: widget.entries,
              emptyText: words.entriesEmpty,
              keeps: _filter.keeps,
              itemBuilder: (entry) => EntryListTile(project: widget.project, entries: widget.entries, entry: entry),
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

  void _askToReverse(BuildContext context) {
    Navigator.of(context).pop();
    ReverseSheet.show(context, (reason) => entries.reverse(entry, reason));
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final mayReverse = project.mayApproveEntries && entry.isApproved && !entry.isReversed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          EntryTile(entry: entry, onTap: () {}),
          if (entry.isExpense && entry.allows(project, Permission.recordEntries)) ...[
            FilledButton(
              key: EntriesScreen.editKey,
              onPressed: () {
                Navigator.of(context).pop();
                EntriesScreen.openForm(context, project, entry);
              },
              child: Text(entry.isRejected ? words.entriesFix : words.entriesEdit, key: EntriesScreen.editKey.label),
            ),
            if (entry.isDraft)
              OutlinedButton(
                key: EntriesScreen.sendKey,
                onPressed: () {
                  Navigator.of(context).pop();
                  showRefusalOf(context, entries.send(entry));
                },
                child: Text(words.entriesSend, key: EntriesScreen.sendKey.label),
              ),
          ],
          if (mayReverse) OutlinedButton(key: EntriesScreen.reverseKey, onPressed: () => _askToReverse(context), child: Text(words.entriesReverse, key: EntriesScreen.reverseKey.label)),
        ],
      ),
    );
  }
}
