import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'account/my_account_screen.dart';
import 'api.dart';
import 'auth/change_password_screen.dart';
import 'auth/session.dart';
import 'auth/sign_in_screen.dart';
import 'home/home_screen.dart';
import 'projects/new_project_screen.dart';
import 'projects/projects.dart';
import 'projects/projects_screen.dart';
import 'projects/registered_projects.dart';
import 'projects/registered_projects_screen.dart';
import 'projects/project.dart';
import 'settings/payment_methods.dart';
import 'settings/payment_methods_screen.dart';
import 'settings/settings_screen.dart';
import 'structure/categories.dart';
import 'structure/categories_screen.dart';
import 'structure/columns.dart';
import 'structure/item_columns_screen.dart';
import 'structure/subgroups_screen.dart';
import 'users/new_user_screen.dart';
import 'users/roles.dart';
import 'users/user_roles_screen.dart';
import 'users/users.dart';
import 'users/users_screen.dart';
import 'words/app_language.dart';
import 'words/no_words_screen.dart';
import 'words/words.dart';

/// Starts the app with the session and the language kept from an earlier start, if any. An app built without its environment's config
/// file stops here, rather than calling an address nobody chose.
Future<void> main() async {
  if (apiBaseUrl.isEmpty) {
    throw StateError('No API address: build with --dart-define-from-file=config/<environment>.json, which sets API_BASE_URL.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  final language = AppLanguage();
  await session.restore();
  await language.restore();
  runApp(RedixApp(session: session, language: language));
}

/// The app: its theme, its languages, and its screens. Without a session every screen leads to sign-in; with a temporary password, to the password change.
class RedixApp extends StatefulWidget {
  /// The app, signed in through [session] and shown in [language].
  const RedixApp({super.key, required this.session, required this.language});

  /// The signed-in session the screens depend on.
  final Session session;

  /// The language the user chose; the phone's while none is chosen.
  final AppLanguage language;

  @override
  State<RedixApp> createState() => _RedixAppState();
}

class _RedixAppState extends State<RedixApp> {
  var _wordsAttempt = 0;
  late final _projects = Projects(widget.session);
  late final _registered = RegisteredProjects(widget.session);
  final _projectUsers = <String, Users>{};
  final _projectRoles = <String, Roles>{};
  final _projectCategories = <String, Categories>{};
  final _columnLists = <String, Columns>{};
  final _projectPaymentMethods = <String, PaymentMethods>{};

  late final _router = GoRouter(
    initialLocation: HomeScreen.landingOf(widget.session),
    refreshListenable: widget.session,
    redirect: (context, state) => _redirect(state.matchedLocation),
    routes: [
      GoRoute(path: ProjectsScreen.path, builder: (context, state) => ProjectsScreen(projects: _projects, session: widget.session)),
      GoRoute(path: SignInScreen.path, builder: (context, state) => SignInScreen(session: widget.session)),
      GoRoute(path: ChangePasswordScreen.path, builder: (context, state) => ChangePasswordScreen(session: widget.session)),
      GoRoute(path: MyAccountScreen.path, builder: (context, state) => MyAccountScreen(language: widget.language, session: widget.session)),
      GoRoute(path: SettingsScreen.path, builder: (context, state) => SettingsScreen(session: widget.session)),
      GoRoute(path: NewProjectScreen.path, builder: (context, state) => NewProjectScreen(projects: _projects)),
      GoRoute(
        path: HomeScreen.path,
        builder: (context, state) => HomeScreen(projectId: state.pathParameters['projectId'] ?? '', projects: _projects),
      ),
      GoRoute(path: NewProjectScreen.registerPath, builder: (context, state) => NewProjectScreen(projects: _projects, isPublic: true)),
      GoRoute(path: RegisteredProjectsScreen.path, builder: (context, state) => RegisteredProjectsScreen(projects: _registered)),
      GoRoute(
        path: UsersScreen.path,
        builder: (context, state) => UsersScreen(users: _usersOf(state.pathParameters['projectId'] ?? ''), projectName: state.extra as String? ?? ''),
      ),
      GoRoute(path: NewUserScreen.path, builder: (context, state) => NewUserScreen(users: _usersOf(state.pathParameters['projectId'] ?? ''))),
      GoRoute(
        path: UserRolesScreen.path,
        builder: (context, state) => UserRolesScreen(
          userId: state.pathParameters['userId'] ?? '',
          users: _usersOf(state.pathParameters['projectId'] ?? ''),
          roles: _rolesOf(state.pathParameters['projectId'] ?? ''),
          projectName: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: CategoriesScreen.path,
        builder: (context, state) => CategoriesScreen(categories: _categoriesOf(state.pathParameters['projectId'] ?? ''), project: state.extra! as Project),
      ),
      GoRoute(path: ItemColumnsScreen.path, builder: (context, state) => _itemColumnsScreen(state.pathParameters['projectId'] ?? '', state.pathParameters['itemId'] ?? '', state.extra! as Project)),
      GoRoute(
        path: PaymentMethodsScreen.path,
        builder: (context, state) => PaymentMethodsScreen(project: state.extra! as Project, projects: _projects, paymentMethods: _paymentMethodsOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: SubgroupsScreen.path,
        builder: (context, state) => SubgroupsScreen(
          itemId: state.pathParameters['itemId'] ?? '',
          project: state.extra! as Project,
          categories: _categoriesOf(state.pathParameters['projectId'] ?? ''),
        ),
      ),
    ],
  );

  Users _usersOf(String projectId) => _projectUsers.putIfAbsent(projectId, () => Users(widget.session, projectId));

  Roles _rolesOf(String projectId) => _projectRoles.putIfAbsent(projectId, () => Roles(widget.session, projectId));

  Categories _categoriesOf(String projectId) => _projectCategories.putIfAbsent(projectId, () => Categories(widget.session, projectId));

  PaymentMethods _paymentMethodsOf(String projectId) => _projectPaymentMethods.putIfAbsent(projectId, () => PaymentMethods(widget.session, projectId));

  Columns _columnsAt(String path) => _columnLists.putIfAbsent(path, () => Columns(widget.session, path));

  ItemColumnsScreen _itemColumnsScreen(String projectId, String itemId, Project project) {
    final categories = _categoriesOf(projectId);
    final item = categories.itemOf(itemId);
    return ItemColumnsScreen(
      item: item,
      categoryName: categories.categoryNameOf(itemId),
      project: project,
      itemColumns: _columnsAt(Columns.itemPath(projectId, itemId)),
      defaultColumns: _columnsAt(Columns.templatePath(projectId, item.type)),
    );
  }

  String? _redirect(String location) {
    final session = widget.session;
    if (!session.isOpen) {
      return location == SignInScreen.path || location == NewProjectScreen.registerPath ? null : SignInScreen.path;
    }
    if (session.mustChangePassword) {
      return location == ChangePasswordScreen.path ? null : ChangePasswordScreen.path;
    }
    return location == SignInScreen.path ? HomeScreen.landingOf(session) : null;
  }

  @override
  void dispose() {
    _router.dispose();
    _projects.dispose();
    _registered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.language,
      builder: (context, _) => MaterialApp.router(
        routerConfig: _router,
        locale: widget.language.locale,
        onGenerateTitle: (context) => Words.of(context).appTitle,
        localizationsDelegates: [
          WordsDelegate(_wordsAttempt),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [for (final language in Words.languages) Locale(language)],
        theme: ThemeData(colorSchemeSeed: const Color(0xFF0E6B68), fontFamily: 'IBMPlexSansArabic'),
        builder: (context, child) => Words.of(context).isEmpty
            ? NoWordsScreen(onRetry: () => setState(() => _wordsAttempt++))
            : child ?? const SizedBox.shrink(),
      ),
    );
  }
}
