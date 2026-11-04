import 'package:flutter/material.dart';

import '../projects/projects.dart';
import '../ui/api_list_body.dart';
import '../words/words.dart';
import 'project_role.dart';
import 'user_project_row.dart';
import 'users.dart';

/// A user's projects and roles (UC-008): every project, with a tick and a role. The user sees only the ticked ones (AC-36.1).
class UserProjectsScreen extends StatefulWidget {
  /// The screen for the user [userId], listing [projects] and changing [users].
  const UserProjectsScreen({super.key, required this.userId, required this.users, required this.projects});

  /// The user being given projects.
  final String userId;

  /// The users, one of whom this screen changes.
  final Users users;

  /// Every project an owner can give.
  final Projects projects;

  /// The screen's route.
  static const path = '/users/:userId/projects';

  /// What this screen does.
  static const hintKey = Key('userProjects.hint');

  /// Whose projects these are.
  static const nameKey = Key('userProjects.name');

  /// The route of this screen for the user [userId].
  static String pathOf(String userId) => '/users/$userId/projects';

  /// The tick of the project [projectId].
  static Key tickKey(String projectId) => Key('userProjects.tick.$projectId');

  /// The choice of [role] in the project [projectId].
  static Key roleKey(String projectId, ProjectRole role) => Key('userProjects.${role.name}.$projectId');

  @override
  State<UserProjectsScreen> createState() => _UserProjectsScreenState();
}

class _UserProjectsScreenState extends State<UserProjectsScreen> {
  @override
  void initState() {
    super.initState();
    widget.projects.load();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.usersProjects)),
      body: ListenableBuilder(
        listenable: widget.users,
        builder: (context, _) {
          final user = widget.users.all.firstWhere((user) => user.id == widget.userId);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, key: UserProjectsScreen.nameKey, style: theme.textTheme.titleMedium),
                    Text(words.usersProjectsHint, key: UserProjectsScreen.hintKey, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: ApiListBody(
                  list: widget.projects,
                  emptyText: words.projectsEmpty,
                  itemBuilder: (project) => UserProjectRow(user: user, project: project, users: widget.users),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
