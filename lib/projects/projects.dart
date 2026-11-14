import '../api_list.dart';
import '../attachments/picked_file.dart';
import '../auth/session.dart';
import 'project.dart';
import 'project_file_refusal.dart';
import '../format/date_format.dart';

/// The projects (UC-006), and the one way to change them.
class Projects extends ApiList<Project> {
  /// The projects of the user signed in through [_session], read again after each renewal of it, so one he was made inactive in shows so soon (redix-api #126 R6):
  /// the one owner of reading the projects again after a renewal.
  Projects(this._session) : super(_session, '/projects', 'projects', Project.fromJson) {
    _session.renewals.addListener(load);
  }

  final Session _session;

  @override
  void dispose() {
    _session.renewals.removeListener(load);
    super.dispose();
  }

  /// [project] as the list holds it now, or [project] itself when the list does not hold it.
  Project latest(Project project) => all.firstWhere((each) => each.id == project.id, orElse: () => project);

  /// Creates a project with its [units], its [partners], each a table of its رأس المال once approved (redix-api #109), and [description], all or nothing, copying its
  /// structure when approved from the earlier project [structureSourceId], or from the default template when that is empty. Returns an empty string once created, otherwise the
  /// word key of the refusal.
  Future<String> create(String name, DateTime startDate, List<String> units, List<String> partners, String description, {String structureSourceId = ''}) => change('/projects', {
    'name': name,
    'startDate': apiDate(startDate),
    'units': units,
    'partners': partners,
    'description': description,
    if (structureSourceId.isNotEmpty) 'structureSourceId': structureSourceId,
  });

  /// Names [project] [name]. Returns an empty string once named, otherwise the word key of the refusal.
  Future<String> rename(Project project, String name) => put('/projects/${project.id}', {'name': name});

  /// Keeps [description] as what [project] is; empty clears it. Returns an empty string once kept, otherwise the word key of the refusal.
  Future<String> describe(Project project, String description) => put('/projects/${project.id}/description', {'description': description});

  /// Names the [unit] of [project] [name]. Returns an empty string once named, otherwise the word key of the refusal.
  Future<String> renameUnit(Project project, Unit unit, String name) => put('/projects/${project.id}/units/${unit.id}', {'name': name});

  /// Deletes the [unit] of [project], which nothing may use. Returns an empty string once deleted, otherwise the word key of the refusal.
  Future<String> deleteUnit(Project project, Unit unit) => deleteAt('/projects/${project.id}/units/${unit.id}');

  /// Adds a unit named [name] to [project]. Returns an empty string once added, otherwise the word key of the refusal.
  Future<String> addUnit(Project project, String name) => change('/projects/${project.id}/units', {'name': name});

  /// Closes [project], which is read-only from then on. Returns an empty string once closed, otherwise the word key of the refusal.
  Future<String> close(Project project) => change('/projects/${project.id}/close', {});

  /// Loads the project file [file] into [project] (UC-071, FR-53), sent as every file is so it waits as long as a file may (UC-070), and reads the projects again, so the
  /// button grays once the project holds its entries (D4). Returns an empty string once loaded, otherwise the word key of the refusal under `projects.loadFile`: what was
  /// loaded is [lastLoad], and every row refused [lastRefusals].
  Future<String> loadFile(Project project, PickedFile file) => sendFile('/projects/${project.id}/project-file', file.name, file.bytes, wordPrefix: 'projects.loadFile');

  /// What the last project file loaded: how many entries, in how many tables, and the number of the report issued, 0 for none (say only what happened).
  ({int entries, int tables, int report}) get lastLoad => (entries: lastAnswer['entries'] as int? ?? 0, tables: lastAnswer['tables'] as int? ?? 0, report: lastAnswer['report'] as int? ?? 0);

  /// Every refusal the last project file's load listed, a row's or a part's, in the order the API found them (AC-53.5, D14).
  List<ProjectFileRefusal> get lastRefusals => [for (final row in lastAnswer['rows'] as List<dynamic>? ?? const []) ProjectFileRefusal.fromJson(row as Map<String, dynamic>)];

  /// The project [id] as last read; none when the list does not hold it (findings row 167).
  Project byId(String id) => all.where((project) => project.id == id).firstOrNull ?? Project.none();
}
