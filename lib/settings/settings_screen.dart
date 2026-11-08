import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account/my_account_screen.dart';
import '../auth/permission.dart';
import '../auth/session.dart';
import '../projects/project.dart';
import '../projects/project_info_screen.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../projects/registered_projects_screen.dart';
import '../structure/categories_screen.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../users/users_screen.dart';
import '../words/words.dart';
import 'default_project_sheet.dart';
import 'payment_methods_screen.dart';
import '../words/app_language.dart';
import '../words/language_tile.dart';

/// Settings (الإعدادات): the way back to the project list, My account, the language, the registered projects for the admin and, for the project it was opened from, More info for everyone in it, and its users, its categories and items, and its payment methods, each for whoever may change them.
class SettingsScreen extends StatelessWidget {
  /// The screen of [project], for the user signed in through [session], whose [projects] the default is chosen among, switching [language].
  const SettingsScreen({super.key, required this.session, required this.projects, required this.project, required this.language});

  /// The language choice its language row changes.
  final AppLanguage language;

  /// The session that says what the user may do.
  final Session session;

  /// The user's projects, among which the default is chosen.
  final Projects projects;

  /// The project it was opened from; [Project.none] from the project list.
  final Project project;

  /// The screen's route from the project list.
  static const path = '/settings';

  /// The screen's route from a project.
  static const projectPath = '/projects/:projectId/settings';

  /// The route of the screen opened from the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/settings';

  /// The way back to the project list.
  static const switchProjectKey = Key('settings.switchProject');

  /// The way into the registered projects, for whoever approves them.
  static const registeredKey = Key('settings.registered');

  /// The way into My account.
  static const myAccountKey = Key('settings.myAccount');

  /// The way into the choice of the default project.
  static const defaultProjectKey = Key('settings.defaultProject');

  /// The way into the project's users.
  static const usersKey = Key('settings.users');

  /// The way into the project's categories and items.
  static const categoriesKey = Key('settings.categories');

  /// The way into the project's payment methods.
  static const paymentMethodsKey = Key('settings.paymentMethods');

  /// The way into More info: the project's name, start date, status, units and description (redix-api 93).
  static const projectInfoKey = Key('settings.projectInfo');

  Widget _row(Key key, IconData icon, String title, VoidCallback onTap) =>
      ListTile(key: key, leading: Icon(icon, key: key.icon), title: Text(title, key: key.title), trailing: Icon(Icons.chevron_right, key: key.trailing), onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.settingsTitle, key: ScreenTitle.titleKey)),
      body: ListenableBuilder(
        listenable: Listenable.merge([session, projects]),
        builder: (context, _) {
          final current = projects.latest(project);
          return ListView(
          children: [
            _row(switchProjectKey, Icons.swap_horiz, words.settingsSwitchProject, () => context.go(ProjectsScreen.path)),
            if (session.may(Permission.approveProjects))
              _row(registeredKey, Icons.approval_outlined, words.registeredTitle, () => context.push(RegisteredProjectsScreen.path)),
            _row(defaultProjectKey, Icons.star_outline, words.settingsDefaultProject, () => DefaultProjectSheet.show(context, session, projects)),
            _row(myAccountKey, Icons.account_circle_outlined, words.myAccountTitle, () => context.push(MyAccountScreen.path)),
            LanguageTile(language: language),
            if (current.may(Permission.readProject))
              _row(projectInfoKey, Icons.info_outline, words.projectInfoTitle, () => context.push(ProjectInfoScreen.pathOf(current.id), extra: current)),
            if (current.may(Permission.manageUsers))
              _row(usersKey, Icons.group_outlined, words.usersTitle, () => context.push(UsersScreen.pathOf(current.id), extra: current.name)),
            if (current.may(Permission.manageStructure))
              _row(categoriesKey, Icons.category_outlined, words.categoriesTitle, () => context.push(CategoriesScreen.pathOf(current.id), extra: current)),
            if (current.may(Permission.manageSettings))
              _row(paymentMethodsKey, Icons.credit_card_outlined, words.paymentMethodsTitle, () => context.push(PaymentMethodsScreen.pathOf(current.id), extra: current)),
          ],
          );
        },
      ),
    );
  }
}
