import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'add_existing_user_dialog.dart';
import 'edit_user_dialog.dart';
import 'new_user_screen.dart';
import 'reset_password_dialog.dart';
import 'user.dart';
import 'user_roles_screen.dart';
import 'user_row.dart';
import 'users.dart';

/// The people of one project, for its manager (UC-007, UC-008): one row per user, with a menu to edit, give roles, reset the password, and disable or enable.
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

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The button that reads the list again.
  static const retryKey = ApiListBody.retryKey;

  /// Edit, in a row's menu.
  static const editKey = Key('users.edit');

  /// Roles, in a row's menu.
  static const rolesKey = Key('users.roles');

  /// Reset password, in a row's menu.
  static const resetPasswordKey = Key('users.resetPassword');

  /// Disable, in a row's menu.
  static const disableKey = Key('users.disable');

  /// Enable, in a row's menu.
  static const enableKey = Key('users.enable');

  /// The name, in the Edit dialog.
  static const editNameKey = Key('users.editName');

  /// The mobile, in the Edit dialog.
  static const editMobileKey = Key('users.editMobile');

  /// Whose password it is, in the Reset password dialog.
  static const resetNameKey = Key('users.resetName');

  /// What a reset means, in the Reset password dialog.
  static const resetExplainKey = Key('users.resetExplain');

  /// The new temporary password, in the Reset password dialog.
  static const resetPasswordFieldKey = Key('users.resetPasswordField');

  /// The button that saves, in the Edit, Reset password and Add an existing user dialogs.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a change was refused, in the Edit, Reset password and Add an existing user dialogs.
  static const dialogMessageKey = ChangeDialog.messageKey;

  /// Who is being disabled, in the disable question.
  static const disableNameKey = ConfirmDialog.subjectKey;

  /// What disabling means, in the disable question.
  static const disableExplainKey = ConfirmDialog.explanationKey;

  /// The button that disables, in the disable question.
  static const confirmDisableKey = ConfirmDialog.confirmKey;

  /// The button that changes nothing, in the disable question.
  static const cancelDisableKey = ConfirmDialog.cancelKey;

  /// The row of the user [id].
  static Key rowKey(String id) => Key('users.row.$id');

  /// The name of the user [id].
  static Key nameKey(String id) => Key('users.name.$id');

  /// The username and mobile of the user [id].
  static Key detailsKey(String id) => Key('users.details.$id');

  /// The roles of the user [id] in this project.
  static Key rolesLineKey(String id) => Key('users.rolesLine.$id');

  /// The badge of the user [id], when disabled.
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
    widget.users.load();
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
    return Scaffold(
      appBar: AppBar(
        title: ScreenTitle(words.usersTitle, subject: widget.projectName),
        actions: [
          IconButton(
            key: UsersScreen.addExistingKey,
            icon: const Icon(Icons.person_search_outlined),
            tooltip: words.usersAddExisting,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AddExistingUserDialog(users: users),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: UsersScreen.newUserKey,
        icon: const Icon(Icons.add),
        label: Text(words.usersNew),
        onPressed: () => context.push(NewUserScreen.pathOf(users.projectId)),
      ),
      body: ApiListBody(
        list: widget.users,
        emptyText: '',
        itemBuilder: (user) => UserRow(
          user: user,
          onEdit: () => showDialog<void>(
            context: context,
            builder: (_) => EditUserDialog(user: user, users: widget.users),
          ),
          onRoles: () => context.push(UserRolesScreen.pathOf(users.projectId, user.id), extra: widget.projectName),
          onResetPassword: () => showDialog<void>(
            context: context,
            builder: (_) => ResetPasswordDialog(user: user, users: widget.users),
          ),
          onDisable: () => _askToDisable(user),
          onEnable: () => showRefusalOf(context, widget.users.enable(user)),
        ),
      ),
    );
  }
}
