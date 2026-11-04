import '../auth/permission.dart';

/// Where a project stands, as the API says it (FR-04).
enum ProjectStatus {
  /// Entries are recorded and approved.
  running,

  /// Closed: read-only, with its reports still available (AC-04.1).
  finished,
}

/// A unit of a project, such as الفلة الغربية.
class Unit {
  /// The unit the API describes in [json].
  Unit.fromJson(Map<String, dynamic> json) : id = json['id'] as String, name = json['name'] as String;

  /// The unit's id.
  final String id;

  /// The unit's name, as it was typed.
  final String name;
}

/// A project as the API answers it. The rules live in the API; the app only draws what it is told.
class Project {
  /// The project the API describes in [json].
  Project.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      startDate = DateTime.parse(json['startDate'] as String),
      status = ProjectStatus.values.byName(json['status'] as String),
      units = [for (final unit in json['units'] as List<dynamic>) Unit.fromJson(unit as Map<String, dynamic>)],
      roles = (json['roles'] as List<dynamic>).cast<String>(),
      _permissions = {...(json['permissions'] as List<dynamic>).cast<String>()};

  /// The project's id.
  final String id;

  /// The project's name, as it was typed.
  final String name;

  /// The day the project started.
  final DateTime startDate;

  /// Running, or finished once closed.
  final ProjectStatus status;

  /// The project's units, in order.
  final List<Unit> units;

  /// The keys of the words naming what the signed-in user is in this project.
  final List<String> roles;

  final Set<String> _permissions;

  /// Whether the signed-in user holds [permission] in this project.
  bool may(Permission permission) => _permissions.contains(permission.name);

  /// True once the project is closed: the app offers no change on it (AC-04.1).
  bool get isFinished => status == ProjectStatus.finished;
}
