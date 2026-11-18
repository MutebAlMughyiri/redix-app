// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../auth/permission.dart';
import '../auth/server_clock.dart';

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
      description = json['description'] as String,
      roleName = json['roleName'] as String? ?? '',
      isInactive = json['isInactive'] as bool,
      holdsEntries = json['holdsEntries'] as bool,
      units = [for (final unit in json['units'] as List<dynamic>) Unit.fromJson(unit as Map<String, dynamic>)],
      timeZone = json['timeZone'] as String? ?? riyadh,
      utcOffsetMinutes = json['utcOffsetMinutes'] as int? ?? riyadhOffsetMinutes,
      _permissions = {...(json['permissions'] as List<dynamic>).cast<String>()},
      _unseenTables = {...(json['unseenTables'] as List<dynamic>? ?? const []).cast<String>()};

  /// No project: what Settings holds when it is opened from the project list, where the signed-in user may do nothing to a project.
  Project.none() : id = '', name = '', startDate = DateTime.utc(1970), status = ProjectStatus.active, rejectionReason = '', description = '', roleName = '', isInactive = false, holdsEntries = false, units = const [], timeZone = riyadh, utcOffsetMinutes = riyadhOffsetMinutes, _permissions = const {}, _unseenTables = const {};

  /// The zone of every project whose manager chose none, and of a project kept on the phone before zones came (redix-app #107, D1).
  static const riyadh = 'Asia/Riyadh';

  /// Riyadh's offset, three hours ahead of UTC all year.
  static const riyadhOffsetMinutes = 180;

  /// The time zone the project is in, its IANA name: its entries' today is counted there.
  final String timeZone;

  /// How far its zone was ahead of UTC when the API answered, in minutes.
  final int utcOffsetMinutes;

  /// The project's today: the server's clock in the project's zone, the same online and offline (redix-app #107, BR-12).
  DateTime todayBy(ServerClock clock) {
    final local = clock.now().toUtc().add(Duration(minutes: utcOffsetMinutes));
    return DateTime(local.year, local.month, local.day);
  }

  /// True for no project.
  bool get isNone => id.isEmpty;

  /// The longest description the API keeps (redix-api 93).
  static const descriptionMaxLength = 2000;

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

  /// What the project is, as its manager wrote it; empty for none (redix-api 93).
  final String description;

  /// What the signed-in user is called in this project, typed by whoever manages its users (Muteb, 9 Nov 2026); empty when nothing was typed.
  final String roleName;

  /// True once a manager made the signed-in user inactive in this project: he keeps his place, permissions and entries there, and cannot open it (redix-api #126 D1).
  final bool isInactive;

  /// True once the project holds an entry, as the API says from the same fact its load refuses with, so no project file may be loaded into it (redix-api #132 D4, D15).
  final bool holdsEntries;

  /// The project's units, in order.
  final List<Unit> units;

  final Set<String> _permissions;

  /// The tables unticked for the signed-in user here, whose entries they do not see (redix-api #106); empty for one kept on the phone before.
  final Set<String> _unseenTables;

  /// Whether the signed-in user holds [permission] in this project.
  bool may(Permission permission) => _permissions.contains(permission.name);

  /// Whether the signed-in user sees the table [tableId], a group or a contract: every one but those unticked for them (redix-api #106 D1, D9).
  bool seesTable(String tableId) => !_unseenTables.contains(tableId);

  /// True while nothing is unticked for the signed-in user, so the periodic report, its files and the contracts' and VAT statements are theirs (redix-api #106 R7, R12).
  bool get seesEveryTable => _unseenTables.isEmpty;

  /// True once the admin has let it in (BR-34).
  bool get isApproved => status == ProjectStatus.active || status == ProjectStatus.finished;

  /// True when the signed-in user may open it: the admin let it in (BR-34), and he is not inactive in it (redix-api #126 D2).
  bool get mayOpen => isApproved && !isInactive;

  /// True once the project is closed: the app offers no change on it (AC-04.1).
  bool get isFinished => status == ProjectStatus.finished;

  /// Whether the signed-in user may manage the project now: its units, its name, its documents, and closing it.
  bool get mayManageProject => !isFinished && may(Permission.manageProject);

  /// Whether the signed-in user holds «ملفات المشروع», which shows the project's file buttons (UC-073 D10).
  bool get mayHandFiles => may(Permission.manageProjectFiles);

  /// Whether the signed-in user may load a project file into it now: whoever holds «ملفات المشروع» (D1, UC-073 D2), into one open that holds no entry yet (D4, redix-api #132).
  bool get mayLoadFile => !isFinished && mayHandFiles && !holdsEntries;

  /// Whether the signed-in user may retrieve an archive over it now: whoever holds «ملفات المشروع», into one not finished (UC-073 R17).
  bool get mayRetrieve => !isFinished && mayHandFiles;

  /// Whether the signed-in user may change the project's structure now.
  bool get mayChangeStructure => !isFinished && may(Permission.manageStructure);

  /// Whether the signed-in user may add a supplier to the project's register now.
  bool get mayAddSupplier => !isFinished && may(Permission.addSupplier);

  /// Whether the signed-in user may enter an expense in the project now.
  bool get mayEnterExpenses => !isFinished && may(Permission.recordEntries);

  /// Whether the signed-in user may enter what counts at once in the project now.
  bool get mayMoveMoney => !isFinished && may(Permission.moveMoney);

  /// Whether the signed-in user may open the project's reports: the periodic report, an item's, a contract's and the VAT statement (redix-api #131).
  bool get maySeeReports => may(Permission.seeReports);

  /// Whether the signed-in user may issue the project's next periodic report now (redix-api #131).
  bool get mayIssueReports => !isFinished && may(Permission.generateReports);

  /// Whether the signed-in user may take a report's Excel and PDF, a finished project's too (redix-api #131).
  bool get mayTakeReportFiles => may(Permission.generateReports);

  /// Whether the signed-in user may open the periodic reports: one document for everyone, for whoever sees every table (redix-api #106 R7).
  bool get maySeePeriodicReports => maySeeReports && seesEveryTable;

  /// Whether the signed-in user may take the files of a whole document, the contracts' statement among them: for whoever sees every table (redix-api #106 R7, R12).
  bool get mayTakeWholeFiles => mayTakeReportFiles && seesEveryTable;

  /// Whether the signed-in user may change the project's settings now.
  bool get mayManageSettings => !isFinished && may(Permission.manageSettings);

  /// Whether the signed-in user may keep a picture or a file in the project now: an invoice, a receipt or a contract's document.
  bool get mayAttachFiles => !isFinished && may(Permission.attachFiles);

  /// Whether the signed-in user may approve or reject entries now.
  bool get mayApproveEntries => !isFinished && may(Permission.approveEntries);

  /// True when the user may delete an entry in this project, which a finished project allows nobody.
  bool get mayDeleteEntries => !isFinished && may(Permission.deleteEntries);

  /// Whether the signed-in user may remove an approved entry now (redix-api #119).
  bool get mayRemoveApprovedEntries => !isFinished && may(Permission.removeApprovedEntries);
}
