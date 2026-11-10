import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api.dart';
import '../attachments/picked_file.dart';
import 'project_entries.dart';
import 'saved_entry.dart';
import '../auth/session.dart';
import '../offline/outbox.dart';

/// Records a project's entries on the API, whatever their table (redix-api #110): a purchase, a contractor payment, revenue or a partner's money, all through one route, or
/// kept in the outbox while there is no network. It sends what was typed; the API computes every figure.
class EntryRecording {
  /// The entries of the project [projectId], recorded through [_session], kept in [_outbox] while offline, and read again into [_entries] once recorded.
  EntryRecording(this._session, this.projectId, this._outbox, this._entries);

  final Session _session;
  final Outbox _outbox;
  final ProjectEntries _entries;

  /// The project these entries belong to.
  final String projectId;

  var _refusedColumnKey = '';
  var _wasKept = false;
  var _lastAnswer = const <String, dynamic>{};

  /// The key of the column the last [record] was refused over; empty when none.
  String get refusedColumnKey => _refusedColumnKey;

  /// Whether the contractor payment last recorded took its contract beyond its value.
  bool get wasOverrun => _lastAnswer['isOverrun'] == true;

  /// Whether the last entry waits on the phone for the network, rather than being sent.
  bool get wasKept => _wasKept;

  /// What the entry [id] holds, to change it; empty when it cannot be read.
  Future<SavedEntry> read(String id) async {
    try {
      final response = await _session.get('/projects/$projectId/entries/$id');
      if (response.statusCode != 200) {
        return SavedEntry.none();
      }
      return switch (jsonOf(response)) {
        final Map<String, dynamic> json => SavedEntry.fromJson(json),
        _ => SavedEntry.none(),
      };
    } on Exception catch (error) {
      debugPrint('Entry not read: $error');
      return SavedEntry.none();
    }
  }

  /// Keeps [body] and its [file] on the phone, when the file could not reach the API, its row saying [title] and [details] (redix-app #103); [editing] names the entry it changes.
  Future<String> keep(Map<String, Object> body, PickedFile file, {String editing = '', String title = '', String details = ''}) => _keep(_routeOf(editing), body, file, title, details);

  /// The route that records an entry, or changes the entry [editing].
  String _routeOf(String editing) => editing.isEmpty ? 'entries' : 'entries/$editing';

  Future<String> _keep(String route, Map<String, Object> body, PickedFile file, String title, String details) async {
    await _outbox.keep(projectId: projectId, route: route, body: body, file: file, title: title, details: details);
    _wasKept = true;
    return '';
  }

  /// Sends [body] to the API, as a new entry or a change of the entry [editing]; kept on the phone with no network, its row saying [title] and [details]. Returns an empty string
  /// once recorded or kept, otherwise the word key of the refusal.
  Future<String> record(Map<String, Object> body, {String editing = '', String title = '', String details = ''}) => _send(_routeOf(editing), body, title, details);

  Future<String> _send(String route, Map<String, Object> body, String title, String details) async {
    _refusedColumnKey = '';
    _wasKept = false;
    try {
      final response = await _session.post('/projects/$projectId/$route', body);
      _lastAnswer = answerOf(response);
      if (response.statusCode < 300) {
        unawaited(_entries.load());
        return '';
      }
      _refusedColumnKey = _lastAnswer['columnKey'] as String? ?? '';
      return refusalOf(_lastAnswer, 'expenses');
    } on Exception catch (error) {
      debugPrint('Entry kept for later: $error');
      return _keep(route, body, PickedFile.none(), title, details);
    }
  }
}
