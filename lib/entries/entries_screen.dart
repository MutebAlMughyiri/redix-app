import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/arabic_spelling.dart';
import '../ui/filter_line.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../ui/one_field_dialog.dart';
import '../ui/screen_title.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'add_entry_screen.dart';
import 'entry_filter.dart';
import 'entry_kind.dart';
import 'entry_row.dart';
import 'entry_card.dart';
import 'searched_entries.dart';

/// A project's entries (UC-037): each person's own, or all of them, searched and filtered on the API a page at a time (redix-app #84, #104), with Show more for as many
/// again; tapping one opens it read only (redix-app #90).
class EntriesScreen extends StatefulWidget {
  /// The entries of [project], in [entries], ready to type a search when [startsSearching].
  const EntriesScreen({super.key, required this.project, required this.entries, this.startsSearching = false});

  /// True when it opens ready to type a search, as the home's search button asks.
  final bool startsSearching;

  /// The address of the screen.
  static const path = '/projects/:projectId/entries';

  /// The address of the screen for the project [projectId], ready to type a search.
  static String searchPathOf(String projectId) => '/projects/$projectId/entries?search=1';

  /// The filter showing the user's own alone, on or off.
  static const mineKey = Key('entries.mine');

  /// The chip opening the list of kinds.
  static const kindChoiceKey = Key('entries.kindChoice');

  /// The kind [kind], `purchase` or `contractorPayment`, in that list.
  static Key kindKey(String kind) => Key('entries.kind.$kind');

  /// The chip opening the list of where an entry stands.
  static const statusChoiceKey = Key('entries.statusChoice');

  /// Where an entry stands, named by its word key [wordKey], in that list.
  static Key statusFilterKey(String wordKey) => Key('entries.statusFilter.$wordKey');

  /// The filter of the period.
  static const periodKey = Key('entries.period');

  /// The filter of the «رقم القيد», which asks for the number (redix-api #128, D4).
  static const numberKey = Key('entries.number');

  /// The button clearing the filters.
  static const clearKey = Key('entries.clear');

  /// Show more, under the entries: as many again as show at a time.
  static const moreKey = Key('entries.more');

  /// The row of the entry [id].
  static Key rowKey(String id) => Key('entries.row.$id');

  /// Who supplied the entry [id], when, and who entered it.
  static Key detailsKey(String id) => Key('entries.details.$id');

  /// The project.
  final Project project;

  /// Its entries, searched on the API.
  final SearchedEntries entries;

  /// The route opening [entry] of the project [projectId] in إضافة قيد, in its table, read only as it was filled, with what can be done to it at its bottom (redix-app #90).
  static String entryPathOf(String projectId, EntryRow entry) =>
      Uri(path: AddEntryScreen.pathOf(projectId), queryParameters: {'entry': entry.id, 'read': '1', if (entry.isRejected) 'reason': entry.rejectionReason}).toString();

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  EntryFilter get _filter => widget.entries.filter;

  @override
  void initState() {
    super.initState();
    widget.entries.open();
  }

  /// Changes the filter by [change] and reads the entries again from the first page.
  void _change(VoidCallback change) {
    setState(change);
    widget.entries.search();
  }

  void _toggle<T>(Set<T> chosen, T value) => _change(() => chosen.contains(value) ? chosen.remove(value) : chosen.add(value));

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(widget.project.startDate.year),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _filter.hasPeriod ? _filter.period : null,
    );
    if (chosen != null && mounted) {
      _change(() => _filter.period = chosen);
    }
  }

  /// Asks for the «رقم القيد» the list keeps, on a number keyboard, in the house's one-field dialog (redix-api #128, D4); saving it empty keeps every number.
  Future<void> _askNumber(Words words) => showDialog<void>(
    context: context,
    builder: (_) => OneFieldDialog(
      title: words.entriesNumberAsk,
      label: words.entriesNumber,
      saveLabel: words.commonSearch,
      name: _filter.hasNumber ? '${_filter.number}' : '',
      keyboardType: TextInputType.number,
      onSave: (typed) async {
        _change(() => _filter.number = int.tryParse(typedForApi(typed)) ?? 0);
        return '';
      },
    ),
  );

  /// Opens [path] and, on coming back, reads the entries again, as the home does: what was opened may have changed there.
  Future<void> _open(String path) async {
    await context.push(path, extra: widget.project);
    await widget.entries.load();
  }

  /// The filters folded under the search line: whose, which kinds, where they stand, when, which «رقم القيد», and the way to clear them.
  List<Widget> _filters(Words words) => [
    FilterLine.toggle(key: EntriesScreen.mineKey, label: words.entriesMine, isOn: _filter.onlyMine, onChanged: (on) => _change(() => _filter.onlyMine = on)),
    FilterLine.choices<EntryKind>(
      key: EntriesScreen.kindChoiceKey,
      label: words.entriesKind,
      values: EntryKind.values,
      chosen: _filter.chosenKinds,
      labelOf: (kind) => words.text(kind.wordKey),
      keyOf: (kind) => EntriesScreen.kindKey(kind.name),
      onToggled: (kind) => _toggle(_filter.chosenKinds, kind),
    ),
    FilterLine.choices<String>(
      key: EntriesScreen.statusChoiceKey,
      label: words.entriesStatus,
      values: EntryFilter.statuses,
      chosen: _filter.chosenStatuses,
      labelOf: words.text,
      keyOf: EntriesScreen.statusFilterKey,
      onToggled: (status) => _toggle(_filter.chosenStatuses, status),
    ),
    FilterLine.toggle(
      key: EntriesScreen.periodKey,
      label: _filter.hasPeriod ? '${words.entriesPeriod}: ${formatDate(_filter.period.start)} – ${formatDate(_filter.period.end)}' : words.entriesPeriod,
      isOn: _filter.hasPeriod,
      onChanged: (_) => _pickPeriod(),
    ),
    FilterLine.toggle(
      key: EntriesScreen.numberKey,
      label: _filter.hasNumber ? words.entriesNumberFilterSet.fill(['${_filter.number}']) : words.entriesNumber,
      isOn: _filter.hasNumber,
      onChanged: (_) => _askNumber(words),
    ),
    if (_filter.isNarrowed) FilterLine.action(key: EntriesScreen.clearKey, label: words.entriesClearFilters, onPressed: () => _change(_filter.clear)),
  ];

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final entries = widget.entries;
    return SearchScope(
      startsOpen: widget.startsSearching,
      onTyped: (typed) => _change(() => _filter.text = typed),
      child: Scaffold(
        appBar: AppBar(title: ScreenTitle(words.entriesTitle, subject: widget.project.name), actions: [SearchIcons.andFilters(filtersInUse: _filter.isNarrowed || _filter.onlyMine)]),
        body: ApiListBody<EntryRow>(
          list: entries,
          emptyText: words.entriesEmpty,
          search: ListSearch.onApi(
            hint: words.entriesSearchHint,
            filters: _filters(words),
          ),
          listOf: (rows) => ListView(
            padding: ApiListBody.padding,
            physics: ApiListBody.physics,
            children: [
              ...rows,
              if (entries.mayHaveMore)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    key: EntriesScreen.moreKey,
                    onPressed: () => showRefusalOf(context, entries.showMore()),
                    child: Text(words.entriesShowMore, key: EntriesScreen.moreKey.label),
                  ),
                ),
            ],
          ),
          itemBuilder: (entry) => SwipeableEntryCard(project: widget.project, entries: entries, entry: entry, onOpen: _open),
        ),
      ),
    );
  }
}
