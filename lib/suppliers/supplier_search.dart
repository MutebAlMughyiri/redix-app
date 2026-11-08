import 'dart:convert';

import '../api_list.dart';
import '../auth/session.dart';
import '../format/number_format.dart';
import 'arabic_spelling.dart';
import 'supplier.dart';

/// What an entry may pick from a project's register (UC-018): what the API finds for what was typed. Nothing about what matches is decided here.
class SupplierSearch extends ApiList<Supplier> {
  /// The search of the project [projectId], seen through [session].
  SupplierSearch(this._session, this.projectId) : super(_session, _pathOf(projectId, ''), 'suppliers', Supplier.fromJson);

  final Session _session;

  /// The project whose register this searches.
  final String projectId;

  var _typed = '';

  static String _pathOf(String projectId, String typed) => '/projects/$projectId/suppliers/search?text=${Uri.encodeQueryComponent(westernDigits(typed.trim()))}';

  /// Whether the list leads with what the signed-in user used most (AC-43.1): only while nothing is typed, and only once they have used something.
  bool get leadsWithMostUsed => _typed.isEmpty && all.isNotEmpty && all.first.timesUsed > 0;

  /// Starts over for a picker that is opening, with nothing typed.
  void openAnew() {
    _typed = '';
    pointAt(_pathOf(projectId, ''));
    loadOnOpen();
  }

  /// Finds what [typed] matches.
  Future<void> find(String typed) {
    _typed = typed.trim();
    pointAt(_pathOf(projectId, typed));
    return load().then((_) => _findInKeptCopy());
  }

  /// With no network the API cannot be asked, so what was kept of the whole register is searched the same way.
  Future<void> _findInKeptCopy() async {
    if (message.isEmpty || _typed.isEmpty) {
      return;
    }
    final kept = await _session.copyOf(_pathOf(projectId, ''));
    if (kept.isEmpty) {
      return;
    }
    final wanted = searchable(_typed);
    final found = [for (final row in jsonDecode(kept) as List<dynamic>) Supplier.fromJson(row as Map<String, dynamic>)];
    show(found.where((supplier) => sameSpelling(supplier.name).contains(wanted) || supplier.vatNumber.contains(wanted)).toList());
  }
}
