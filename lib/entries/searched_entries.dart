import '../format/date_format.dart';
import '../format/number_format.dart';
import 'entry_filter.dart';
import 'newest_entries.dart';

/// A project's entries as the Entries screen searches them, on the API, a page at a time (redix-app #104): what was typed, whose, which kinds, where they stand and when,
/// as many at a time as this phone shows, Show more reading as many again. No screen reads every entry for it.
class SearchedEntries extends NewestEntries {
  /// The entries of the project [projectId], seen through [session], searched as many at a time as [localConfig] keeps.
  SearchedEntries(super.session, super.projectId, super.localConfig);

  /// What narrows the entries; [search] reads them again once it changes.
  final filter = EntryFilter();

  @override
  Map<String, Object> get query => {
    if (filter.text.trim().isNotEmpty) 'text': westernDigits(filter.text.trim()),
    if (filter.onlyMine) 'mine': 'true',
    if (filter.chosenKinds.isNotEmpty) 'kinds': [for (final kind in filter.chosenKinds) kind.name],
    if (filter.chosenStatuses.isNotEmpty) 'statuses': [for (final status in filter.chosenStatuses) status.replaceFirst('entries.', '')],
    if (filter.hasPeriod) 'from': apiDate(filter.period.start),
    if (filter.hasPeriod) 'to': apiDate(filter.period.end),
  };

  /// Reads the first page again with [filter] as it now stands.
  Future<void> search() => readFirstPage();
}
