import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'add_entry_screen.dart';
import 'entry_filter.dart';
import 'entry_kind.dart';
import 'entry_row.dart';
import 'entry_tile.dart';
import 'project_entries.dart';
import 'reverse_sheet.dart';

/// A project's entries (UC-037): each person's own, or all of them, searched and filtered (redix-app #84); tapping one opens it read only (redix-app #90).
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



  /// Who supplied the entry [id], when, and who entered it.
  static Key detailsKey(String id) => Key('entries.details.$id');

  /// The project.
  final Project project;

  /// Its entries.
  final ProjectEntries entries;

  /// Opens [entry] in إضافة قيد, in its table, read only as it was filled, with what can be done to it at its bottom (redix-app #90).
  static void openEntry(BuildContext context, Project project, EntryRow entry) {
    context.push(Uri(path: AddEntryScreen.pathOf(project.id), queryParameters: {'entry': entry.id, 'read': '1', if (entry.isRejected) 'reason': entry.rejectionReason}).toString(), extra: project);
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
      EntriesScreen.openEntry(context, widget.project, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.entriesTitle, subject: widget.project.name)),
      body: Column(
        children: [
          ListenableBuilder(listenable: widget.entries, builder: (_, _) => _filters(words)),
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
