import 'package:flutter/foundation.dart';

import '../api.dart';
import '../auth/session.dart';
import 'earlier_entry.dart';

/// Records a project's expenses on the API, purchases (UC-022) and contractor payments (UC-027). It sends what was typed; the API computes every figure.
class Expenses {
  /// The expenses of the project [projectId], recorded through [_session].
  Expenses(this._session, this.projectId);

  final Session _session;

  /// The project these expenses belong to.
  final String projectId;

  var _refusedColumnKey = '';
  var _lastAnswer = const <String, dynamic>{};

  /// The key of the column the last [record] was refused over; empty when none.
  String get refusedColumnKey => _refusedColumnKey;

  /// The entry the last [record] repeated; only after the refusal `expenses.duplicateInvoice`.
  EarlierEntry get earlier => EarlierEntry.fromJson(_lastAnswer['earlier'] as Map<String, dynamic>);

  /// Whether the contractor payment last recorded took its contract beyond its value.
  bool get wasOverrun => _lastAnswer['isOverrun'] == true;

  /// Sends the purchase [body]. Returns an empty string once recorded, otherwise the word key of the refusal.
  Future<String> record(Map<String, Object> body) => _send('expenses', body);

  /// Sends the contractor payment [body]. Returns an empty string once recorded, otherwise the word key of the refusal.
  Future<String> recordContractorPayment(Map<String, Object> body) => _send('contractor-payments', body);

  Future<String> _send(String route, Map<String, Object> body) async {
    _refusedColumnKey = '';
    try {
      final response = await _session.post('/projects/$projectId/$route', body);
      _lastAnswer = response.body.isEmpty ? const <String, dynamic>{} : jsonOf(response) as Map<String, dynamic>;
      if (response.statusCode < 300) {
        return '';
      }
      _refusedColumnKey = _lastAnswer['columnKey'] as String? ?? '';
      return 'expenses.${_lastAnswer['code'] as String? ?? 'refused'}';
    } on Exception catch (error) {
      debugPrint('Expense not recorded: $error');
      return 'expenses.noConnection';
    }
  }
}
