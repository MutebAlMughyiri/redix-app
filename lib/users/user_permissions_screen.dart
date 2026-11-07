import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../ui/refresh_button.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'permission_tick.dart';
import 'user.dart';
import 'users.dart';

/// What one person may do in one project: a tick for each permission, saved at once. Unticking See the project takes them out of it.
class UserPermissionsScreen extends StatelessWidget {
  /// The screen for the person [userId] among [users].
  const UserPermissionsScreen({super.key, required this.userId, required this.users, required this.projectName});

  /// The person.
  final String userId;

  /// The project's people, among them this one.
  final Users users;

  /// The project's name, for the title.
  final String projectName;

  /// The screen's route.
  static const path = '/projects/:projectId/users/:userId/permissions';

  /// What this screen does.
  static const hintKey = Key('userPermissions.hint');

  /// Whose permissions these are.
  static const nameKey = Key('userPermissions.name');

  /// The route of this screen for the person [userId] in the project [projectId].
  static String pathOf(String projectId, String userId) => '/projects/$projectId/users/$userId/permissions';

  /// The tick of [permission].
  static Key permissionKey(Permission permission) => Key('userPermissions.${permission.name}');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.permissionsTitle, subject: projectName), actions: [RefreshButton(onRefresh: users.load)]),
      body: ListenableBuilder(
        listenable: users,
        builder: (context, _) {
          final matching = users.all.where((user) => user.id == userId);
          if (matching.isEmpty) {
            return const SizedBox.shrink();
          }
          final User user = matching.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(user.displayName, key: nameKey, style: theme.textTheme.titleMedium),
              Text(words.permissionsHint, key: hintKey, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              for (final permission in Permission.inAProject)
                PermissionTick(
                  key: permissionKey(permission),
                  permission: permission,
                  value: user.holds(permission),
                  onChanged: (ticked) => showRefusalOf(context, ticked ? users.give(user, permission) : users.take(user, permission)),
                ),
            ],
          );
        },
      ),
    );
  }
}
