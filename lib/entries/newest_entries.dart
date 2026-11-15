import 'package:flutter/foundation.dart';

import '../config/local_config.dart';
import 'entry_row.dart';
import 'project_entries.dart';

/// The newest of a project's entries, as many at a time as this phone shows (redix-app #105): the home reads only these, never the whole list, and each Show more reads as many
/// again. Every read asks for the pages shown at the count chosen now, so coming back keeps what showed and a count changed in Settings applies at the next read. The one
/// owner of reading entries a page at a time: the Entries screen's search adds its own [query] (redix-app #104).
class NewestEntries extends ProjectEntries {
  /// The newest entries of the project [projectId], seen through [session], as many at a time as [_localConfig] keeps.
  NewestEntries(super.session, super.projectId, this._localConfig);

  final LocalConfig _localConfig;
  var _pages = 1;

  int get _asked => _pages * _localConfig.entriesShown;

  /// Shows the first page again, for the home opening, read once the frame in progress is drawn.
  void openFirstPage() {
    _pages = 1;
    loadOnOpen();
  }

  /// What the read asks of the API besides how many: nothing for the newest.
  @protected
  Map<String, Object> get query => const {};

  /// Reads the first page again: what a change of [query] does.
  @protected
  Future<void> readFirstPage() {
    _pages = 1;
    return load();
  }

  @override
  Future<void> load() {
    pointAt(Uri(path: '/projects/$projectId/entries', queryParameters: {...query, 'take': '$_asked'}).toString());
    return super.load();
  }

  /// Reads as many again as show at a time. Returns an empty string once read, otherwise the word key saying they could not be; what showed stays, and Show more with it.
  Future<String> showMore() async {
    final asked = ++_pages;
    await load();
    if (message.isNotEmpty && _pages == asked) {
      _pages--;
    }
    return message;
  }

  /// True while the last read filled every page asked for, so older entries may follow.
  bool get mayHaveMore => all.length >= _asked;

  /// The newest entries, as many as show at a time, whatever Show more added: what the home-screen widget lists (redix-app #86 R9).
  List<EntryRow> get firstPage => all.take(_localConfig.entriesShown).toList();
}
