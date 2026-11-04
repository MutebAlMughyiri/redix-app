import '../api_list.dart';
import '../auth/session.dart';
import 'project.dart';

/// The projects (UC-006), and the one way to change them.
class Projects extends ApiList<Project> {
  /// The projects of the user signed in through [session].
  Projects(Session session) : super(session, '/projects', 'projects', Project.fromJson);

  /// Creates a project with its [units], all or nothing. Returns an empty string once created, otherwise the word key of the refusal.
  Future<String> create(String name, DateTime startDate, List<String> units) =>
      change('/projects', {'name': name, 'startDate': startDate.toIso8601String().substring(0, 10), 'units': units});

  /// Adds a unit named [name] to [project]. Returns an empty string once added, otherwise the word key of the refusal.
  Future<String> addUnit(Project project, String name) => change('/projects/${project.id}/units', {'name': name});

  /// Closes [project], which is read-only from then on. Returns an empty string once closed, otherwise the word key of the refusal.
  Future<String> close(Project project) => change('/projects/${project.id}/close', {});
}
