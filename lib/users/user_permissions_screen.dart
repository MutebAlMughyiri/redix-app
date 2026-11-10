import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../partners/partners.dart';
import '../ui/api_list_body.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'permission_ticks.dart';
import 'user.dart';
import 'users.dart';

/// What one person may do in one project: a tick for each permission, saved at once, and the partners whose capital they see (redix-api #106). Unticking See the project takes them out of it.
class UserPermissionsScreen extends StatefulWidget {
  /// The screen for the person [userId] among [users], choosing among the project's [partners].
  const UserPermissionsScreen({super.key, required this.userId, required this.users, required this.partners, required this.projectName});

  /// The person.
  final String userId;

  /// The project's people, among them this one.
  final Users users;

  /// The project's partners, to choose whose capital this person sees.
  final Partners partners;

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
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.partners.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final users = widget.users;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.permissionsTitle, subject: widget.projectName)),
      body: ListenableBuilder(
        listenable: Listenable.merge([users, widget.partners]),
        builder: (context, _) {
          final matching = users.all.where((user) => user.id == widget.userId);
          if (matching.isEmpty) {
            return const SizedBox.shrink();
          }
          final User user = matching.first;
          return RefreshIndicator(
            onRefresh: users.load,
            child: ListView(
              physics: ApiListBody.physics,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(user.displayName, key: UserPermissionsScreen.nameKey, style: theme.textTheme.titleMedium),
                Text(words.permissionsHint, key: UserPermissionsScreen.hintKey, style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                PermissionTicks(
                  keyOf: UserPermissionsScreen.permissionKey,
                  holds: user.holds,
                  onChangedOf: (permission) => (ticked) => showRefusalOf(context, ticked ? users.give(user, permission) : users.take(user, permission)),
                  partners: widget.partners.all,
                  chosen: (partner) => user.sees(partner.id),
                  onChooseOf: (partner) => (ticked) => showRefusalOf(context, ticked ? users.choosePartner(user, partner.id) : users.unchoosePartner(user, partner.id)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
