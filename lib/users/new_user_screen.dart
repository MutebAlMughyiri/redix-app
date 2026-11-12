import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/parts_line.dart';
import '../auth/permission.dart';
import '../partners/partners.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'permission_ticks.dart';
import 'users.dart';
import '../ui/form_error.dart';
import '../ui/form_button_style.dart';
import '../ui/act_once.dart';

/// The new user form (UC-007): their name, username, mobile and a temporary password they change at first sign-in (AC-02.1). A new login is born in a project.
class NewUserScreen extends StatefulWidget {
  /// The form, adding to the project's [users], choosing among its [partners] whose capital the new one sees (redix-api #106).
  const NewUserScreen({super.key, required this.users, required this.partners});

  /// The users the new one joins.
  final Users users;

  /// The project's partners.
  final Partners partners;

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

  /// What they are called in this project, beside their username (Muteb, 9 Nov 2026).
  static const roleNameKey = Key('newUser.roleName');

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
  final _roleName = TextEditingController();
  final _password = TextEditingController();
  var _message = '';
  final _ticked = {Permission.readProject};
  final _chosen = <String>{};

  @override
  void initState() {
    super.initState();
    widget.partners.loadOnOpen();
  }

  /// Ticks or unticks [permission]; a capital tick takes the other, and unticking chosen capital forgets the partners chosen under it (redix-api #106).
  void _tick(Permission permission, bool ticked) => setState(() {
    if (!ticked) {
      _ticked.remove(permission);
    } else {
      if (Permission.capitalTicks.contains(permission)) {
        _ticked.removeAll(Permission.capitalTicks);
      }
      _ticked.add(permission);
    }
    if (!_ticked.contains(Permission.seeChosenCapital)) {
      _chosen.clear();
    }
  });

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _mobile.dispose();
    _roleName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() => _message = '');
    final refusal = await widget.users.create(_name.text, _username.text, _roleName.text, _mobile.text, _password.text, _ticked, _chosen);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      context.pop();
      return;
    }
    setState(() => _message = refusal);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    InputDecoration field(String label, {String helper = ''}) =>
        InputDecoration(labelText: label, helperText: helper.isEmpty ? null : helper, helperMaxLines: 2);
    return Scaffold(
      appBar: AppBar(title: Text(words.usersNew, key: ScreenTitle.titleKey)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message.isNotEmpty) FormError(text: words.text(_message), textKey: NewUserScreen.messageKey),
              TextField(
                key: NewUserScreen.nameKey,
                controller: _name,
                decoration: field(words.usersName, helper: words.usersNameHint),
              ),
              const SizedBox(height: 16),
              TextField(key: NewUserScreen.usernameKey, controller: _username, autocorrect: false, decoration: field(words.usersUsername)),
              const SizedBox(height: 16),
              TextField(key: NewUserScreen.roleNameKey, controller: _roleName, decoration: field(words.usersRoleName)),
              const SizedBox(height: 16),
              TextField(key: NewUserScreen.mobileKey, controller: _mobile, keyboardType: TextInputType.phone, decoration: field(words.usersMobile)),
              const SizedBox(height: 16),
              TextField(
                key: NewUserScreen.passwordKey,
                controller: _password,
                autocorrect: false,
                decoration: field(words.usersTemporaryPassword, helper: partsLine([words.usersTemporaryPasswordHint, words.commonPasswordRules])),
              ),
              const SizedBox(height: 16),
              Text(words.permissionsTitle, key: NewUserScreen.permissionsHeadingKey, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: widget.partners,
                builder: (context, _) => PermissionTicks(
                  keyOf: NewUserScreen.permissionKey,
                  holds: _ticked.contains,
                  onChangedOf: (permission) => permission == Permission.readProject ? null : (ticked) => _tick(permission, ticked),
                  partners: widget.partners.all,
                  chosen: (partner) => _chosen.contains(partner.id),
                  onChooseOf: (partner) => (ticked) => setState(() => ticked ? _chosen.add(partner.id) : _chosen.remove(partner.id)),
                ),
              ),
              const SizedBox(height: 24),
              ActOnce(builder: (once) => FilledButton(
                key: NewUserScreen.submitKey,
                onPressed: once(_add),
                style: formButtonStyle,
                child: Text(words.usersAdd, key: NewUserScreen.submitKey.label),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
