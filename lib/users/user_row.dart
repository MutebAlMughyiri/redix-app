// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'user.dart';
import 'users_screen.dart';
import '../ui/app_color.dart';
import '../format/parts_line.dart';
import '../ui/row_menu.dart';

/// One user on the list: their name, username, mobile and how many permissions they hold, a badge when inactive in this project (redix-api #126 D1), and a menu of
/// what can be done to them.
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
    return Card.outlined(
      key: UsersScreen.rowKey(user.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: UsersScreen.rowKey(user.id).body,
        leading: CircleAvatar(key: UsersScreen.rowKey(user.id).icon, child: Text(user.displayName.characters.take(1).toString(), key: UsersScreen.rowKey(user.id).label)),
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              user.displayName,
              key: UsersScreen.nameKey(user.id),
              style: AppColor.quiet.textUnless(context, !user.isInactive),
            ),
            if (user.isInactive)
              Chip(
                key: UsersScreen.statusKey(user.id),
                label: Text(words.usersDisabled, key: UsersScreen.statusKey(user.id).label),
                backgroundColor: AppColor.mutedSurface.of(context),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partsLine([user.username, user.roleName, user.mobile]), key: UsersScreen.detailsKey(user.id)),
            Text(words.permissionsCount.fill(['${user.permissionCount}']), key: UsersScreen.permissionsLineKey(user.id)),
            Text(user.lastSeenIn(words), key: UsersScreen.lastSeenKey(user.id)),
          ],
        ),
        trailing: rowMenu(UsersScreen.menuKey(user.id), [
            rowMenuItem(UsersScreen.editKey, words.usersEdit, onEdit),
            rowMenuItem(UsersScreen.permissionsKey, words.permissionsTitle, onPermissions),
            rowMenuItem(UsersScreen.resetPasswordKey, words.usersResetPassword, onResetPassword),
            if (user.isInactive)
              rowMenuItem(UsersScreen.enableKey, words.usersEnable, onEnable)
            else
              rowMenuItem(UsersScreen.disableKey, words.usersDisable, onDisable),
          ]),
      ),
    );
  }
}
