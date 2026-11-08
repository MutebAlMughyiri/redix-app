import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api.dart';
import '../attachments/picked_file.dart';
import '../auth/session.dart';
import 'local_store.dart';
import 'pending_entry.dart';

/// The entries waiting on this phone for the network (UC-029, FR-16). It tries them while the app runs, so they are sent within a minute of the network returning (AC-16.1). Each carries
/// the id made on the phone, so an upload that was cut and sent again lands once (AC-16.3). They survive a sign-out, and go only with the person who entered them.
class Outbox extends ChangeNotifier {
  /// The entries sent through [_session], kept in [_store].
  Outbox(this._session, this._store) {
    _tries = Timer.periodic(tryEvery, (_) => send());
  }

  /// How often the entries are tried: AC-16.1 allows a minute for all of them.
  static const tryEvery = Duration(seconds: 20);

  static const _folder = 'outbox';
  static const _files = 'outbox-files';

  final Session _session;
  final LocalStore _store;
  final _all = <PendingEntry>[];
  var _isSending = false;
  late final Timer _tries;

  /// The signed-in person's entries in the project [projectId].
  List<PendingEntry> of(String projectId) => _all.where((entry) => entry.ownerId == _session.userId && entry.projectId == projectId).toList();

  /// Reads what an earlier run kept, and tries it.
  Future<void> start() async {
    for (final name in await _store.namesIn(_folder)) {
      _all.add(PendingEntry.fromJson(jsonDecode(await _store.read(_folder, name)) as Map<String, dynamic>));
    }
    notifyListeners();
    await send();
  }

  @override
  void dispose() {
    _tries.cancel();
    super.dispose();
  }

  /// Keeps an entry of the project [projectId] for the API [route], with [file] if it has one still to send.
  Future<void> keep({required String projectId, required String route, required Map<String, Object> body, required PickedFile file}) async {
    final entry = PendingEntry(ownerId: _session.userId, projectId: projectId, route: route, body: body, fileName: file.name);
    if (!file.isNone) {
      await _store.writeBytes(_files, entry.id, file.bytes);
    }
    await _save(entry);
    _all.add(entry);
    notifyListeners();
  }

  /// Sends a refused [entry] again.
  Future<void> sendAgain(PendingEntry entry) async {
    entry.refusal = '';
    await _save(entry);
    notifyListeners();
    await send();
  }

  /// Forgets [entry] and its file.
  Future<void> discard(PendingEntry entry) async {
    _all.remove(entry);
    await _store.delete(_folder, entry.id);
    await _store.delete(_files, entry.id);
    notifyListeners();
  }

  /// Tries what waits, one at a time, until the network fails.
  Future<void> send() async {
    if (_isSending || !_session.isOpen) {
      return;
    }
    _isSending = true;
    try {
      for (final entry in _all.where((entry) => entry.ownerId == _session.userId && !entry.isRefused).toList()) {
        await _sendOne(entry);
      }
    } on Exception catch (error) {
      debugPrint('Entries not sent yet: $error');
    } finally {
      _isSending = false;
    }
  }

  Future<void> _sendOne(PendingEntry entry) async {
    if (entry.fileName.isNotEmpty) {
      final bytes = await _store.readBytes(_files, entry.id);
      final kept = await _session.postFile('/projects/${entry.projectId}/attachments', entry.fileName, bytes);
      if (kept.statusCode >= 500) {
        return;
      }
      final answer = answerOf(kept);
      if (kept.statusCode >= 300) {
        return _refuse(entry, refusalOf(answer, 'attachments'));
      }
      entry
        ..body['attachmentId'] = answer['id'] as String
        ..fileName = '';
      await _save(entry);
    }
    final sent = await _session.post('/projects/${entry.projectId}/${entry.route}', entry.body);
    if (sent.statusCode >= 500) {
      return;
    }
    if (sent.statusCode >= 300) {
      return _refuse(entry, refusalOf(answerOf(sent), 'expenses'));
    }
    await discard(entry);
  }

  Future<void> _refuse(PendingEntry entry, String refusal) async {
    entry.refusal = refusal;
    await _save(entry);
    notifyListeners();
  }

  Future<void> _save(PendingEntry entry) => _store.write(_folder, entry.id, jsonEncode(entry));
}
