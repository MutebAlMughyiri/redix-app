import '../api_list.dart';
import '../auth/session.dart';
import 'partner.dart';

/// A project's partners (UC-016), and the one way to change them. Each change returns an empty string once made, otherwise the word key of the refusal.
class Partners extends ApiList<Partner> {
  /// The partners of the project [projectId], seen through [session].
  Partners(Session session, this.projectId) : super(session, '/projects/$projectId/partners', 'partners', Partner.fromJson);

  /// The project these partners belong to.
  final String projectId;

  /// Adds a partner named [name], whose login is [userId], or who has none when that is empty.
  Future<String> add(String name, String userId) => change('/projects/$projectId/partners', {'name': name, if (userId.isNotEmpty) 'userId': userId});

  /// Names [partner] [name] and sets their login: [userId], or none when that is empty.
  Future<String> edit(Partner partner, String name, String userId) => change('/projects/$projectId/partners/${partner.id}', {'name': name, if (userId.isNotEmpty) 'userId': userId});
}
