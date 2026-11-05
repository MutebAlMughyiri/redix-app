import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'account/my_account_screen.dart';
import 'accounts/accounts.dart';
import 'accounts/accounts_screen.dart';
import 'accounts/offered_accounts.dart';
import 'api.dart';
import 'attachments/attachments.dart';
import 'attachments/invoice_capture.dart';
import 'auth/change_password_screen.dart';
import 'auth/session.dart';
import 'auth/sign_in_screen.dart';
import 'contracts/contracts.dart';
import 'contracts/contracts_screen.dart';
import 'expenses/add_expense_screen.dart';
import 'expenses/creditable_invoices.dart';
import 'expenses/expenses.dart';
import 'home/home_screen.dart';
import 'partners/partners.dart';
import 'partners/partners_screen.dart';
import 'projects/members.dart';
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
import 'structure/category.dart';
import 'structure/columns.dart';
import 'structure/item_columns_screen.dart';
import 'structure/offered_items.dart';
import 'structure/subgroups_screen.dart';
import 'suppliers/suppliers.dart';
import 'suppliers/suppliers_screen.dart';
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
  /// The app, signed in through [session], shown in [language], and reaching the phone's camera and files through [capture].
  const RedixApp({super.key, required this.session, required this.language, this.capture = const InvoiceCapture()});

  /// The signed-in session the screens depend on.
  final Session session;

  /// The language the user chose; the phone's while none is chosen.
  final AppLanguage language;

  /// The phone's camera and files.
  final InvoiceCapture capture;

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
  final _projectAccounts = <String, Accounts>{};
  final _projectMembers = <String, Members>{};
  final _projectPartners = <String, Partners>{};
  final _projectSuppliers = <String, Suppliers>{};
  final _offeredItemLists = <String, OfferedItems>{};
  final _projectContracts = <String, Contracts>{};
  final _projectAttachments = <String, Attachments>{};
  final _projectExpenses = <String, Expenses>{};
  final _projectCreditableInvoices = <String, CreditableInvoices>{};
  final _projectOfferedAccounts = <String, OfferedAccounts>{};

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
        builder: (context, state) => HomeScreen(projectId: state.pathParameters['projectId'] ?? '', projects: _projects, accounts: _accountsOf(state.pathParameters['projectId'] ?? '')),
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
        path: AccountsScreen.path,
        builder: (context, state) => AccountsScreen(project: state.extra! as Project, accounts: _accountsOf(state.pathParameters['projectId'] ?? ''), members: _membersOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: PartnersScreen.path,
        builder: (context, state) => PartnersScreen(project: state.extra! as Project, partners: _partnersOf(state.pathParameters['projectId'] ?? ''), members: _membersOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: SuppliersScreen.path,
        builder: (context, state) => SuppliersScreen(
          project: state.extra! as Project,
          suppliers: _suppliersOf(state.pathParameters['projectId'] ?? ''),
          items: _offeredItemsOf(state.pathParameters['projectId'] ?? '', ItemType.purchases),
        ),
      ),
      GoRoute(
        path: ContractsScreen.path,
        builder: (context, state) => ContractsScreen(
          project: state.extra! as Project,
          contracts: _contractsOf(state.pathParameters['projectId'] ?? ''),
          suppliers: _suppliersOf(state.pathParameters['projectId'] ?? ''),
          items: _offeredItemsOf(state.pathParameters['projectId'] ?? '', ItemType.contractorPayments),
          attachments: _attachmentsOf(state.pathParameters['projectId'] ?? ''),
          capture: widget.capture,
        ),
      ),
      GoRoute(path: AddExpenseScreen.path, builder: (context, state) => _addExpenseScreen(state.pathParameters['projectId'] ?? '', state.extra! as Project)),
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

  Accounts _accountsOf(String projectId) => _projectAccounts.putIfAbsent(projectId, () => Accounts(widget.session, projectId));

  Members _membersOf(String projectId) => _projectMembers.putIfAbsent(projectId, () => Members(widget.session, projectId));

  Partners _partnersOf(String projectId) => _projectPartners.putIfAbsent(projectId, () => Partners(widget.session, projectId));

  Suppliers _suppliersOf(String projectId) => _projectSuppliers.putIfAbsent(projectId, () => Suppliers(widget.session, projectId));

  OfferedItems _offeredItemsOf(String projectId, ItemType type) => _offeredItemLists.putIfAbsent('$projectId/${type.name}', () => OfferedItems(widget.session, projectId, type));

  Contracts _contractsOf(String projectId) => _projectContracts.putIfAbsent(projectId, () => Contracts(widget.session, projectId));

  Attachments _attachmentsOf(String projectId) => _projectAttachments.putIfAbsent(projectId, () => Attachments(widget.session, projectId));

  AddExpenseScreen _addExpenseScreen(String projectId, Project project) => AddExpenseScreen(
    project: project,
    expenses: _projectExpenses.putIfAbsent(projectId, () => Expenses(widget.session, projectId)),
    items: _offeredItemsOf(projectId, ItemType.purchases),
    accounts: _projectOfferedAccounts.putIfAbsent(projectId, () => OfferedAccounts(widget.session, projectId)),
    paymentMethods: _paymentMethodsOf(projectId),
    suppliers: _suppliersOf(projectId),
    creditableInvoices: _projectCreditableInvoices.putIfAbsent(projectId, () => CreditableInvoices(widget.session, projectId)),
    columnsOf: (itemId) => _columnsAt(Columns.itemPath(projectId, itemId)),
    attachments: _attachmentsOf(projectId),
    capture: widget.capture,
  );

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
