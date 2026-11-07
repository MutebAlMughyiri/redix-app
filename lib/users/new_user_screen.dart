import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/permission.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'permission_tick.dart';
import 'users.dart';

/// The new user form (UC-007): their name, username, mobile and a temporary password they change at first sign-in (AC-02.1). A new login is born in a project.
class NewUserScreen extends StatefulWidget {
  /// The form, adding to the project's [users].
  const NewUserScreen({super.key, required this.users});

  /// The users the new one joins.
  final Users users;

  /// The screen's route.
  static const path = '/projects/:projectId/users/new';

  /// The route of this screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/users/new';

  /// The user's name.
  static const nameKey = Key('newUser.name');

  /// The user's username.
  static const usernameKey = Key('newUser.username');

  /// The user's mobile.
  static const mobileKey = Key('newUser.mobile');

  /// The temporary password, shown as typed so the project manager can pass it on.
  static const passwordKey = Key('newUser.password');

  /// The button that adds the user.
  static const submitKey = Key('newUser.submit');

  /// The line that says why the user was refused.
  static const messageKey = Key('newUser.message');

  /// The tick of [permission]; See the project is always ticked.
  static Key permissionKey(Permission permission) => Key('newUser.${permission.name}');

  /// The heading over the permissions.
  static const permissionsHeadingKey = Key('newUser.permissionsHeading');

  @override
  State<NewUserScreen> createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  var _message = '';
  var _saving = false;
  final _ticked = {Permission.readProject};

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() {
      _saving = true;
      _message = '';
    });
    final refusal = await widget.users.create(_name.text, _username.text, _mobile.text, _password.text, _ticked);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      context.pop();
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    InputDecoration field(String label, {String helper = ''}) =>
        InputDecoration(labelText: label, helperText: helper.isEmpty ? null : helper, border: const OutlineInputBorder());
    return Scaffold(
      appBar: AppBar(title: Text(words.usersNew, key: ScreenTitle.titleKey)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: NewUserScreen.nameKey,
              controller: _name,
              decoration: field(words.usersName, helper: words.usersNameHint),
            ),
            const SizedBox(height: 16),
            TextField(key: NewUserScreen.usernameKey, controller: _username, autocorrect: false, decoration: field(words.usersUsername)),
            const SizedBox(height: 16),
            TextField(key: NewUserScreen.mobileKey, controller: _mobile, keyboardType: TextInputType.phone, decoration: field(words.usersMobile)),
            const SizedBox(height: 16),
            TextField(
              key: NewUserScreen.passwordKey,
              controller: _password,
              autocorrect: false,
              decoration: field(words.usersTemporaryPassword, helper: words.usersTemporaryPasswordHint),
            ),
            const SizedBox(height: 16),
            Text(words.permissionsTitle, key: NewUserScreen.permissionsHeadingKey, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final permission in Permission.inAProject)
              PermissionTick(
                key: NewUserScreen.permissionKey(permission),
                permission: permission,
                value: _ticked.contains(permission),
                onChanged: permission == Permission.readProject ? null : (ticked) => setState(() => ticked ? _ticked.add(permission) : _ticked.remove(permission)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: NewUserScreen.submitKey,
              onPressed: _saving ? null : _add,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(words.usersAdd, key: NewUserScreen.submitKey.label),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                words.text(_message),
                key: NewUserScreen.messageKey,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
