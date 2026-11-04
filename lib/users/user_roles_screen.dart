import 'package:flutter/material.dart';

import '../ui/api_list_body.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'role.dart';
import 'roles.dart';
import 'user.dart';
import 'users.dart';

/// What one person does in one project: a tick for each role the API lists, saved at once. Someone can hold more than one, and taking the last takes them out.
class UserRolesScreen extends StatefulWidget {
  /// The screen for the person [userId] among [users], offering [roles].
  const UserRolesScreen({super.key, required this.userId, required this.users, required this.roles, required this.projectName});

  /// The person.
  final String userId;

  /// The project's people, among them this one.
  final Users users;

  /// The roles the project can give.
  final Roles roles;

  /// The project's name, for the title.
  final String projectName;

  /// The screen's route.
  static const path = '/projects/:projectId/users/:userId/roles';

  /// What this screen does.
  static const hintKey = Key('userRoles.hint');

  /// Whose roles these are.
  static const nameKey = Key('userRoles.name');

  /// The route of this screen for the person [userId] in the project [projectId].
  static String pathOf(String projectId, String userId) => '/projects/$projectId/users/$userId/roles';

  /// The tick of the role [roleId].
  static Key roleKey(String roleId) => Key('userRoles.role.$roleId');

  @override
  State<UserRolesScreen> createState() => _UserRolesScreenState();
}

class _UserRolesScreenState extends State<UserRolesScreen> {
  @override
  void initState() {
    super.initState();
    widget.roles.load();
  }

  Widget _tick(Words words, User user, Role role) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 8),
    child: CheckboxListTile(
      key: UserRolesScreen.roleKey(role.id),
      controlAffinity: ListTileControlAffinity.leading,
      value: user.holds(role),
      title: Text(words.text(role.wordKey)),
      onChanged: (_) => showRefusalOf(context, user.holds(role) ? widget.users.take(user, role) : widget.users.give(user, role)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${words.usersRoles} · ${widget.projectName}')),
      body: ListenableBuilder(
        listenable: widget.users,
        builder: (context, _) {
          final matching = widget.users.all.where((user) => user.id == widget.userId);
          if (matching.isEmpty) {
            return const SizedBox.shrink();
          }
          final user = matching.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, key: UserRolesScreen.nameKey, style: theme.textTheme.titleMedium),
                    Text(words.usersRolesHint, key: UserRolesScreen.hintKey, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: ApiListBody(list: widget.roles, emptyText: '', itemBuilder: (role) => _tick(words, user, role)),
              ),
            ],
          );
        },
      ),
    );
  }
}
