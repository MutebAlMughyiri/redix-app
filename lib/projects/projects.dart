import '../api_list.dart';
import '../auth/session.dart';
import 'project.dart';

/// The projects (UC-006), and the one way to change them.
class Projects extends ApiList<Project> {
  /// The projects of the user signed in through [session].
  Projects(Session session) : super(session, '/projects', 'projects', Project.fromJson);

  /// Creates a project with its [units], all or nothing, copying its structure when approved from the earlier project [structureSourceId], or from the default template when that is empty.
  /// Returns an empty string once created, otherwise the word key of the refusal.
  Future<String> create(String name, DateTime startDate, List<String> units, {String structureSourceId = ''}) => change('/projects', {
    'name': name,
    'startDate': startDate.toIso8601String().substring(0, 10),
    'units': units,
    if (structureSourceId.isNotEmpty) 'structureSourceId': structureSourceId,
  });

  /// Names [project] [name]. Returns an empty string once named, otherwise the word key of the refusal.
  Future<String> rename(Project project, String name) => change('/projects/${project.id}', {'name': name});

  /// Names the [unit] of [project] [name]. Returns an empty string once named, otherwise the word key of the refusal.
  Future<String> renameUnit(Project project, Unit unit, String name) => change('/projects/${project.id}/units/${unit.id}', {'name': name});

  /// Deletes the [unit] of [project], which nothing may use. Returns an empty string once deleted, otherwise the word key of the refusal.
  Future<String> deleteUnit(Project project, Unit unit) => change('/projects/${project.id}/units/${unit.id}/delete', {});

  /// Adds a unit named [name] to [project]. Returns an empty string once added, otherwise the word key of the refusal.
  Future<String> addUnit(Project project, String name) => change('/projects/${project.id}/units', {'name': name});

  /// Closes [project], which is read-only from then on. Returns an empty string once closed, otherwise the word key of the refusal.
  Future<String> close(Project project) => change('/projects/${project.id}/close', {});
}
