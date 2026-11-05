import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api.dart';
import '../attachments/picked_file.dart';
import '../entries/project_entries.dart';
import '../auth/session.dart';
import '../offline/outbox.dart';
import 'earlier_entry.dart';

/// Records a project's expenses on the API, purchases (UC-022) and contractor payments (UC-027). It sends what was typed; the API computes every figure.
class Expenses {
  /// The expenses of the project [projectId], recorded through [_session].
  Expenses(this._session, this.projectId, this._outbox, this._entries);

  final Session _session;
  final Outbox _outbox;
  final ProjectEntries _entries;

  /// The project these expenses belong to.
  final String projectId;

  var _refusedColumnKey = '';
  var _wasKept = false;
  var _lastAnswer = const <String, dynamic>{};

  /// The key of the column the last [record] was refused over; empty when none.
  String get refusedColumnKey => _refusedColumnKey;

  /// The entry the last [record] repeated; only after the refusal `expenses.duplicateInvoice`.
  EarlierEntry get earlier => EarlierEntry.fromJson(_lastAnswer['earlier'] as Map<String, dynamic>);

  /// Whether the contractor payment last recorded took its contract beyond its value.
  bool get wasOverrun => _lastAnswer['isOverrun'] == true;

  /// Whether the last entry waits on the phone for the network, rather than being sent.
  bool get wasKept => _wasKept;

  /// What the entry [id] holds, to change it; empty when it cannot be read.
  Future<Map<String, dynamic>> read(String id) async {
    try {
      final response = await _session.get('/projects/$projectId/entries/$id');
      return response.statusCode == 200 ? jsonOf(response) as Map<String, dynamic> : const {};
    } on Exception catch (error) {
      debugPrint('Entry not read: $error');
      return const {};
    }
  }

  /// Keeps the purchase [body] and its [file] on the phone, when the file could not reach the API; [editing] names the entry it changes.
  Future<String> keepPurchase(Map<String, Object> body, PickedFile file, {String editing = ''}) => _keep(_routeOf('expenses', editing), body, file);

  /// Keeps the contractor payment [body] and its [file] on the phone, when the file could not reach the API; [editing] names the entry it changes.
  Future<String> keepContractorPayment(Map<String, Object> body, PickedFile file, {String editing = ''}) => _keep(_routeOf('contractor-payments', editing), body, file);

  String _routeOf(String route, String editing) => editing.isEmpty ? route : '$route/$editing';

  Future<String> _keep(String route, Map<String, Object> body, PickedFile file) async {
    await _outbox.keep(projectId: projectId, route: route, body: body, file: file);
    _wasKept = true;
    return '';
  }

  /// Sends the purchase [body]. Returns an empty string once recorded, otherwise the word key of the refusal.
  Future<String> record(Map<String, Object> body, {String editing = ''}) => _send(_routeOf('expenses', editing), body);

  /// Sends the contractor payment [body]. Returns an empty string once recorded, otherwise the word key of the refusal.
  Future<String> recordContractorPayment(Map<String, Object> body, {String editing = ''}) => _send(_routeOf('contractor-payments', editing), body);

  Future<String> _send(String route, Map<String, Object> body) async {
    _refusedColumnKey = '';
    _wasKept = false;
    try {
      final response = await _session.post('/projects/$projectId/$route', body);
      _lastAnswer = response.body.isEmpty ? const <String, dynamic>{} : jsonOf(response) as Map<String, dynamic>;
      if (response.statusCode < 300) {
        unawaited(_entries.load());
        return '';
      }
      _refusedColumnKey = _lastAnswer['columnKey'] as String? ?? '';
      return 'expenses.${_lastAnswer['code'] as String? ?? 'refused'}';
    } on Exception catch (error) {
      debugPrint('Expense kept for later: $error');
      return _keep(route, body, PickedFile.none());
    }
  }
}
