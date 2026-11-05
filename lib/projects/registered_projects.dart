import '../api_list.dart';
import '../auth/session.dart';
import 'registered_project.dart';

/// What is waiting for the admin (UC-066), and the one way to decide it. Each decision returns an empty string once made, otherwise the word key of the refusal.
class RegisteredProjects extends ApiList<RegisteredProject> {
  /// The waiting projects, seen by the admin signed in through [session].
  RegisteredProjects(Session session) : super(session, '/projects/registered', 'registered', RegisteredProject.fromJson);

  /// Lets [project] in.
  Future<String> approve(RegisteredProject project) => change('/projects/${project.id}/approve', {});

  /// Refuses [project], saying why in [reason], which its manager sees.
  Future<String> reject(RegisteredProject project, String reason) => change('/projects/${project.id}/reject', {'reason': reason});
}
