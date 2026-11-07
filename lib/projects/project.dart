import '../auth/permission.dart';

/// Where a project stands, as the API says it (FR-04), each knowing its word so no reader needs to tell them apart.
enum ProjectStatus {
  /// Entries are recorded and approved.
  active('projects.active'),

  /// Closed: read-only, with its reports still available (AC-04.1).
  finished('projects.finished'),

  /// Registered, and waiting for the admin; nothing can be done in it yet (BR-34).
  pendingApproval('projects.pending'),

  /// Refused by the admin, saying why; nothing can be done in it (BR-34).
  rejected('projects.rejected');

  const ProjectStatus(this.wordKey);

  /// The key of the word that names this status.
  final String wordKey;
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
      rejectionReason = json['rejectionReason'] as String,
      units = [for (final unit in json['units'] as List<dynamic>) Unit.fromJson(unit as Map<String, dynamic>)],
      _permissions = {...(json['permissions'] as List<dynamic>).cast<String>()};

  /// No project: what Settings holds when it is opened from the project list, where the signed-in user may do nothing to a project.
  Project.none() : id = '', name = '', startDate = DateTime.utc(1970), status = ProjectStatus.active, rejectionReason = '', units = const [], _permissions = const {};

  /// The project's id.
  final String id;

  /// The project's name, as it was typed.
  final String name;

  /// The day the project started.
  final DateTime startDate;

  /// Where it stands.
  final ProjectStatus status;

  /// Why the admin refused it; empty otherwise.
  final String rejectionReason;

  /// The project's units, in order.
  final List<Unit> units;

  final Set<String> _permissions;

  /// Whether the signed-in user holds [permission] in this project.
  bool may(Permission permission) => _permissions.contains(permission.name);

  /// True once the admin has let it in, so it can be opened (BR-34).
  bool get isApproved => status == ProjectStatus.active || status == ProjectStatus.finished;

  /// True once the project is closed: the app offers no change on it (AC-04.1).
  bool get isFinished => status == ProjectStatus.finished;

  /// Whether the signed-in user may manage the project now: its units, its name, its documents, and closing it.
  bool get mayManageProject => !isFinished && may(Permission.manageProject);

  /// Whether the signed-in user may change the project's structure now.
  bool get mayChangeStructure => !isFinished && may(Permission.manageStructure);

  /// Whether the signed-in user may add a supplier to the project's register now.
  bool get mayAddSupplier => !isFinished && may(Permission.addSupplier);

  /// Whether the signed-in user may enter an expense in the project now.
  bool get mayEnterExpenses => !isFinished && may(Permission.recordEntries);

  /// Whether the signed-in user may enter what counts at once in the project now.
  bool get mayMoveMoney => !isFinished && may(Permission.moveMoney);

  /// Whether the signed-in user may change the project's settings now.
  bool get mayManageSettings => !isFinished && may(Permission.manageSettings);

  /// Whether the signed-in user may keep a picture or a file in the project now: an invoice, a receipt or a contract's document.
  bool get mayAttachFiles => !isFinished && may(Permission.attachFiles);
}
