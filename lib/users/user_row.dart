import 'package:flutter/material.dart';

import '../words/words.dart';
import 'user.dart';
import 'users_screen.dart';

/// One user on the list: their name, username, mobile and how many permissions they hold, a badge when disabled, and a menu of what can be done to them.
class UserRow extends StatelessWidget {
  /// The row of [user], calling the given callback when its menu item is chosen.
  const UserRow({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onPermissions,
    required this.onResetPassword,
    required this.onDisable,
    required this.onEnable,
  });

  /// The user this row shows.
  final User user;

  /// Called when Edit is chosen.
  final VoidCallback onEdit;

  /// Called when Permissions is chosen.
  final VoidCallback onPermissions;

  /// Called when Reset password is chosen.
  final VoidCallback onResetPassword;

  /// Called when Disable is chosen.
  final VoidCallback onDisable;

  /// Called when Enable is chosen.
  final VoidCallback onEnable;

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
            if (!user.isActive)
              Chip(
                key: UsersScreen.statusKey(user.id),
                label: Text(words.usersDisabled),
                backgroundColor: colors.surfaceContainerHighest,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.mobile.isEmpty ? user.username : '${user.username} · ${user.mobile}', key: UsersScreen.detailsKey(user.id)),
            Text(words.permissionsCount.replaceFirst('{0}', '${user.permissionCount}'), key: UsersScreen.permissionsLineKey(user.id)),
          ],
        ),
        trailing: PopupMenuButton<VoidCallback>(
          key: UsersScreen.menuKey(user.id),
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            PopupMenuItem(key: UsersScreen.editKey, value: onEdit, child: Text(words.usersEdit)),
            PopupMenuItem(key: UsersScreen.permissionsKey, value: onPermissions, child: Text(words.permissionsTitle)),
            PopupMenuItem(key: UsersScreen.resetPasswordKey, value: onResetPassword, child: Text(words.usersResetPassword)),
            if (user.isActive)
              PopupMenuItem(key: UsersScreen.disableKey, value: onDisable, child: Text(words.usersDisable))
            else
              PopupMenuItem(key: UsersScreen.enableKey, value: onEnable, child: Text(words.usersEnable)),
          ],
        ),
      ),
    );
  }
}
