import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/api_list_body.dart';
import '../ui/confirm_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/title_bar_add.dart';
import '../ui/messages.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'add_existing_user_dialog.dart';
import 'edit_user_dialog.dart';
import 'new_user_screen.dart';
import 'reset_password_dialog.dart';
import 'user.dart';
import 'user_permissions_screen.dart';
import 'user_row.dart';
import 'users.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../words/word_fill.dart';
import '../format/parts_line.dart';

/// The people of one project, for its manager (UC-007, UC-008): one row per user, with a menu to edit, tick permissions, reset the password, and make them inactive in
/// this project or active again (redix-api #126 D1).
class UsersScreen extends StatefulWidget {
  /// The screen, showing and changing the [users] of the project [projectName].
  const UsersScreen({super.key, required this.users, required this.projectName});

  /// The users this screen shows and changes.
  final Users users;

  /// The name of their project.
  final String projectName;

  /// The screen's route.
  static const path = '/projects/:projectId/users';

  /// The route of the people of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/users';

  /// The button that adds someone who already has a login.
  static const addExistingKey = Key('users.addExisting');

  /// Their username, in the Add an existing user dialog.
  static const existingUsernameKey = Key('users.existingUsername');

  /// The button that opens the new user form.
  static const newUserKey = Key('users.new');

  /// Edit, in a row's menu.
  static const editKey = Key('users.edit');

  /// Permissions, in a row's menu.
  static const permissionsKey = Key('users.permissions');

  /// Reset password, in a row's menu.
  static const resetPasswordKey = Key('users.resetPassword');

  /// Disable, in a row's menu: makes the person inactive in this project (redix-api #126 D1).
  static const disableKey = Key('users.disable');

  /// Enable, in a row's menu: makes the person active in this project again.
  static const enableKey = Key('users.enable');

  /// The name, in the Edit dialog.
  static const editNameKey = Key('users.editName');

  /// The mobile, in the Edit dialog.
  static const editMobileKey = Key('users.editMobile');

  /// What the person is called in this project, in the dialog that changes them (Muteb, 9 Nov 2026).
  static const editRoleNameKey = Key('users.editRoleName');

  /// Whose password it is, in the Reset password dialog.
  static const resetNameKey = Key('users.resetName');

  /// What a reset means, in the Reset password dialog.
  static const resetExplainKey = Key('users.resetExplain');

  /// The new temporary password, in the Reset password dialog.
  static const resetPasswordFieldKey = Key('users.resetPasswordField');

  /// The row of the user [id].
  static Key rowKey(String id) => Key('users.row.$id');

  /// The name of the user [id].
  static Key nameKey(String id) => Key('users.name.$id');

  /// The username and mobile of the user [id].
  static Key detailsKey(String id) => Key('users.details.$id');

  /// How many permissions the user [id] holds in this project.
  static Key permissionsLineKey(String id) => Key('users.permissionsLine.$id');

  /// The badge of the user [id], when inactive in this project.
  static Key statusKey(String id) => Key('users.status.$id');

  /// The menu of the user [id].
  static Key menuKey(String id) => Key('users.menu.$id');

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    widget.users.loadOnOpen();
  }

  void _askToDisable(User user) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.usersDisableQuestion,
        subject: user.displayName,
        explanation: words.usersDisableExplain,
        confirmLabel: words.usersDisable,
        onConfirm: () => showRefusalOf(context, widget.users.disable(user)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final users = widget.users;
    return SearchScope(
      child: Scaffold(
        appBar: AppBar(
          title: ScreenTitle(words.usersTitle, subject: widget.projectName),
          actions: [
            const SearchIcons(),
            TitleBarAdd(buttonKey: UsersScreen.newUserKey, tooltip: words.usersNew, onPressed: () => context.push(NewUserScreen.pathOf(users.projectId))),
            IconButton(
              key: UsersScreen.addExistingKey,
              icon: Icon(Icons.person_search_outlined, key: UsersScreen.addExistingKey.icon),
              tooltip: words.usersAddExisting,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AddExistingUserDialog(users: users),
              ),
            ),
          ],
        ),
        body: ApiListBody<User>(
          list: widget.users,
          emptyText: words.usersNoMatch,
          search: ListSearch(hint: words.commonSearchIn.fill([words.usersTitle]), textOf: (user) => partsLine([user.displayName, user.username, user.mobile, user.roleName])),
          itemBuilder: (user) => UserRow(
            user: user,
            onEdit: () => showDialog<void>(
              context: context,
              builder: (_) => EditUserDialog(user: user, users: widget.users),
            ),
            onPermissions: () => context.push(UserPermissionsScreen.pathOf(users.projectId, user.id), extra: widget.projectName),
            onResetPassword: () => showDialog<void>(
              context: context,
              builder: (_) => ResetPasswordDialog(user: user, users: widget.users),
            ),
            onDisable: () => _askToDisable(user),
            onEnable: () => showRefusalOf(context, widget.users.enable(user)),
          ),
        ),
      ),
    );
  }
}
