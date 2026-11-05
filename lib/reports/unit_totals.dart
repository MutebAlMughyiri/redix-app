import '../api_list.dart';
import '../auth/session.dart';

/// What one unit has cost, as the API added it (UC-060, FR-15).
class UnitTotal {
  /// A unit's total as the API answers it.
  UnitTotal.fromJson(Map<String, dynamic> json)
    : unitId = json['unitId'] as String,
      name = json['name'] as String,
      isShared = json['isShared'] as bool,
      direct = (json['direct'] as num).toDouble(),
      fromShared = (json['fromShared'] as num).toDouble(),
      total = (json['total'] as num).toDouble();

  /// The unit.
  final String unitId;

  /// Its name.
  final String name;

  /// True for the shared unit, whose total is what was shared and never split.
  final bool isShared;

  /// What was recorded against it.
  final double direct;

  /// Its part of the shared expenses that were split.
  final double fromShared;

  /// Both together.
  final double total;
}

/// What each of a project's units has cost, the shared unit last.
class UnitTotals extends ApiList<UnitTotal> {
  /// The units of the project [projectId], seen through [session].
  UnitTotals(Session session, String projectId) : super(session, '/projects/$projectId/reports/units', 'reports', UnitTotal.fromJson);
}
