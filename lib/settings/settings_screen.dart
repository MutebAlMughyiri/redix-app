import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account/my_account_screen.dart';
import '../auth/session.dart';
import '../projects/projects_screen.dart';
import '../users/users_screen.dart';
import '../words/words.dart';

/// Settings (الإعدادات): the way into My account and, for owners, the app's settings. Each later settings use case adds its own row.
class SettingsScreen extends StatelessWidget {
  /// The screen, for the user signed in through [session].
  const SettingsScreen({super.key, required this.session});

  /// The session that says whether the user is an owner.
  final Session session;

  /// The screen's route.
  static const path = '/settings';

  /// The way into the projects, for owners.
  static const projectsKey = Key('settings.projects');

  /// The way into the users, for owners.
  static const usersKey = Key('settings.users');

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
            if (session.isOwner) ...[
              ListTile(
                key: projectsKey,
                leading: const Icon(Icons.home_work_outlined),
                title: Text(words.projectsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(ProjectsScreen.path),
              ),
              ListTile(
                key: usersKey,
                leading: const Icon(Icons.group_outlined),
                title: Text(words.usersTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(UsersScreen.path),
              ),
            ],
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
