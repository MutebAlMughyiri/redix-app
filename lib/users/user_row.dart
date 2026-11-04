import 'package:flutter/material.dart';

import '../words/words.dart';
import 'user.dart';
import 'users_screen.dart';

/// One user on the list: their name, username, mobile and projects, a badge for an owner or a disabled user, and a menu of what can be done to them.
class UserRow extends StatelessWidget {
  /// The row of [user], calling the given callback when its menu item is chosen.
  const UserRow({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onProjects,
    required this.onResetPassword,
    required this.onDisable,
    required this.onEnable,
  });

  /// The user this row shows.
  final User user;

  /// Called when Edit is chosen.
  final VoidCallback onEdit;

  /// Called when Projects and roles is chosen.
  final VoidCallback onProjects;

  /// Called when Reset password is chosen.
  final VoidCallback onResetPassword;

  /// Called when Disable is chosen.
  final VoidCallback onDisable;

  /// Called when Enable is chosen.
  final VoidCallback onEnable;

  String _projectsLine(Words words) {
    if (user.isOwner) {
      return words.usersEveryProject;
    }
    if (user.projects.isEmpty) {
      return words.usersNoProjects;
    }
    return user.projects.map((project) => '${words.text(project.role.wordKey)} · ${project.name}').join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      key: UsersScreen.rowKey(user.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(user.displayName.characters.take(1).toString())),
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              user.displayName,
              key: UsersScreen.nameKey(user.id),
              style: user.isActive ? null : TextStyle(color: colors.onSurfaceVariant),
            ),
            if (user.isOwner || !user.isActive)
              Chip(
                key: UsersScreen.statusKey(user.id),
                label: Text(user.isOwner ? words.usersOwner : words.usersDisabled),
                backgroundColor: user.isOwner ? colors.tertiaryContainer : colors.surfaceContainerHighest,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.mobile.isEmpty ? user.username : '${user.username} · ${user.mobile}', key: UsersScreen.detailsKey(user.id)),
            Text(_projectsLine(words), key: UsersScreen.projectsLineKey(user.id)),
          ],
        ),
        trailing: PopupMenuButton<VoidCallback>(
          key: UsersScreen.menuKey(user.id),
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            PopupMenuItem(key: UsersScreen.editKey, value: onEdit, child: Text(words.usersEdit)),
            if (!user.isOwner) ...[
              PopupMenuItem(key: UsersScreen.projectsKey, value: onProjects, child: Text(words.usersProjects)),
              PopupMenuItem(key: UsersScreen.resetPasswordKey, value: onResetPassword, child: Text(words.usersResetPassword)),
              if (user.isActive)
                PopupMenuItem(key: UsersScreen.disableKey, value: onDisable, child: Text(words.usersDisable))
              else
                PopupMenuItem(key: UsersScreen.enableKey, value: onEnable, child: Text(words.usersEnable)),
            ],
          ],
        ),
      ),
    );
  }
}
