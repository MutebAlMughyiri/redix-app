import '../config/local_config.dart';
import 'project_entries.dart';

/// The newest of a project's entries, as many at a time as this phone shows (redix-app #105): the home reads only these, never the whole list, and each Show more reads as many
/// again. Every read asks for the pages shown at the count chosen now, so coming back keeps what showed and a count changed in Settings applies at the next read.
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

  @override
  Future<void> load() {
    pointAt('/projects/$projectId/entries?take=$_asked');
    return super.load();
  }

  /// Reads as many again as show at a time. Returns an empty string once read, otherwise the word key saying they could not be; what showed stays, and Show more with it.
  Future<String> showMore() async {
    _pages++;
    await load();
    if (message.isNotEmpty) {
      _pages--;
    }
    return message;
  }

  /// True while the last read filled every page asked for, so older entries may follow.
  bool get mayHaveMore => all.length >= _asked;
}
