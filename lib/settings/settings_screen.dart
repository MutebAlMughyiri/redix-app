import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account/my_account_screen.dart';
import '../auth/permission.dart';
import '../auth/session.dart';
import '../projects/projects_screen.dart';
import '../projects/registered_projects_screen.dart';
import '../words/words.dart';

/// Settings (الإعدادات): the way back to the project list, My account and, for the admin, the registered projects. Each later settings use case adds its own row.
class SettingsScreen extends StatelessWidget {
  /// The screen, for the user signed in through [session].
  const SettingsScreen({super.key, required this.session});

  /// The session that says what the user may do.
  final Session session;

  /// The screen's route.
  static const path = '/settings';

  /// The way back to the project list.
  static const switchProjectKey = Key('settings.switchProject');

  /// The way into the registered projects, for whoever approves them.
  static const registeredKey = Key('settings.registered');

  /// The way into My account.
  static const myAccountKey = Key('settings.myAccount');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.settingsTitle)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) => ListView(
          children: [
            ListTile(
              key: switchProjectKey,
              leading: const Icon(Icons.swap_horiz),
              title: Text(words.settingsSwitchProject),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(ProjectsScreen.path),
            ),
            if (session.may(Permission.approveProjects))
              ListTile(
                key: registeredKey,
                leading: const Icon(Icons.approval_outlined),
                title: Text(words.registeredTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RegisteredProjectsScreen.path),
              ),
            ListTile(
              key: myAccountKey,
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(words.myAccountTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(MyAccountScreen.path),
            ),
          ],
        ),
      ),
    );
  }
}
