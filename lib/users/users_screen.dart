import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'edit_user_dialog.dart';
import 'new_user_screen.dart';
import 'reset_password_dialog.dart';
import 'user_projects_screen.dart';
import 'user.dart';
import 'user_row.dart';
import 'users.dart';

/// The users (UC-007): one row per user, with a menu to edit, reset the password, and disable or enable. An owner can only be edited (BR-29).
class UsersScreen extends StatefulWidget {
  /// The screen, showing and changing [users].
  const UsersScreen({super.key, required this.users});

  /// The users this screen shows and changes.
  final Users users;

  /// The screen's route.
  static const path = '/users';

  /// The button that opens the new user form.
  static const newUserKey = Key('users.new');

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The button that reads the list again.
  static const retryKey = ApiListBody.retryKey;

  /// Edit, in a row's menu.
  static const editKey = Key('users.edit');

  /// Projects and roles, in a row's menu.
  static const projectsKey = Key('users.projects');

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

  /// The button that saves, in the Edit and Reset password dialogs.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a change was refused, in the Edit and Reset password dialogs.
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

  /// The projects and roles of the user [id].
  static Key projectsLineKey(String id) => Key('users.projectsLine.$id');

  /// The badge of the user [id], an owner or disabled.
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
    return Scaffold(
      appBar: AppBar(title: Text(words.usersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: UsersScreen.newUserKey,
        icon: const Icon(Icons.add),
        label: Text(words.usersNew),
        onPressed: () => context.push(NewUserScreen.path),
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
          onProjects: () => context.push(UserProjectsScreen.pathOf(user.id)),
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
