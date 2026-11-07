import 'dart:async';
import 'documents/documents.dart';
import 'documents/documents_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'account/my_account_screen.dart';
import 'accounts/accounts.dart';
import 'accounts/accounts_screen.dart';
import 'accounts/offered_accounts.dart';
import 'accounts/reconcile_screen.dart';
import 'accounts/reconciliation.dart';
import 'accounts/transfer_screen.dart';
import 'accounts/transfers.dart';
import 'api.dart';
import 'attachments/attachments.dart';
import 'attachments/invoice_capture.dart';
import 'attachments/picked_file.dart';
import 'auth/change_password_screen.dart';
import 'auth/session.dart';
import 'auth/sign_in_screen.dart';
import 'contractor_payments/contractor_payment_screen.dart';
import 'contracts/contracts.dart';
import 'contracts/contracts_screen.dart';
import 'expenses/add_expense_screen.dart';
import 'expenses/creditable_invoices.dart';
import 'expenses/expenses.dart';
import 'home/home_screen.dart';
import 'partners/capital.dart';
import 'partners/capital_move_screen.dart';
import 'partners/liquidation.dart';
import 'partners/liquidation_screen.dart';
import 'partners/capital_movements.dart';
import 'partners/movements_screen.dart';
import 'partners/partners.dart';
import 'partners/partners_screen.dart';
import 'approvals/approvals.dart';
import 'approvals/approvals_screen.dart';
import 'attachments/attachment_screen.dart';
import 'entries/entries_screen.dart';
import 'entries/project_entries.dart';
import 'notifications/notifications.dart';
import 'notifications/notifications_screen.dart';
import 'offline/outbox.dart';
import 'offline/project_sync.dart';
import 'offline/waiting_screen.dart';
import 'projects/members.dart';
import 'reports/dashboard.dart';
import 'reports/item_report.dart';
import 'reports/item_report_screen.dart';
import 'reports/periodic_report_screen.dart';
import 'reports/periodic_reports.dart';
import 'reports/report_files.dart';
import 'reports/reports_screen.dart';
import 'reports/vat_statement.dart';
import 'reports/vat_statement_screen.dart';
import 'revenue/revenue_form_screen.dart';
import 'revenue/revenue_screen.dart';
import 'revenue/revenues.dart';
import 'revenue/sales_invoice_screen.dart';
import 'projects/new_project_screen.dart';
import 'projects/projects.dart';
import 'projects/projects_screen.dart';
import 'projects/registered_projects.dart';
import 'projects/registered_projects_screen.dart';
import 'projects/project.dart';
import 'settings/payment_methods.dart';
import 'settings/payment_methods_screen.dart';
import 'settings/settings_screen.dart';
import 'sharing/attachable_entries.dart';
import 'sharing/share_screen.dart';
import 'structure/categories.dart';
import 'structure/categories_screen.dart';
import 'structure/category.dart';
import 'structure/columns.dart';
import 'structure/item_columns_screen.dart';
import 'structure/item_tables.dart';
import 'structure/item_tables_screen.dart';
import 'structure/offered_items.dart';
import 'suppliers/suppliers.dart';
import 'suppliers/suppliers_screen.dart';
import 'users/new_user_screen.dart';
import 'users/user_permissions_screen.dart';
import 'users/users.dart';
import 'users/users_screen.dart';
import 'words/app_language.dart';
import 'words/no_words_screen.dart';
import 'words/words.dart';
import 'config/app_config.dart';

/// Starts the app with the session and the language kept from an earlier start, if any. An app built without its environment's config
/// file stops here, rather than calling an address nobody chose.
Future<void> main() async {
  if (apiBaseUrl.isEmpty) {
    throw StateError('No API address: build with --dart-define-from-file=config/<environment>.json, which sets API_BASE_URL.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  final language = AppLanguage();
  await config.restore();
  unawaited(config.refresh());
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
  var _shared = PickedFile.none();
  late final StreamSubscription<PickedFile> _sharing;
  late final _projects = Projects(widget.session);
  late final _outbox = Outbox(widget.session, widget.session.store);
  late final _sync = ProjectSync(widget.session);
  late final _registered = RegisteredProjects(widget.session);
  late final _notifications = Notifications(widget.session);
  final _projectUsers = <String, Users>{};
  final _projectCategories = <String, Categories>{};
  final _columnLists = <String, Columns>{};
  final _projectPaymentMethods = <String, PaymentMethods>{};
  final _projectAccounts = <String, Accounts>{};
  final _projectApprovals = <String, Approvals>{};
  final _projectEntries = <String, ProjectEntries>{};
  final _projectMembers = <String, Members>{};
  final _projectPartners = <String, Partners>{};
  final _projectSuppliers = <String, Suppliers>{};
  final _offeredItemLists = <String, OfferedItems>{};
  final _projectContracts = <String, Contracts>{};
  final _projectAttachments = <String, Attachments>{};
  final _projectExpenses = <String, Expenses>{};
  final _projectCreditableInvoices = <String, CreditableInvoices>{};
  final _projectOfferedAccounts = <String, OfferedAccounts>{};
  final _projectAttachable = <String, AttachableEntries>{};
  final _projectTransfers = <String, Transfers>{};
  final _projectReconciliations = <String, Reconciliations>{};
  final _projectCapital = <String, Capital>{};
  final _projectRevenues = <String, Revenues>{};
  final _projectVat = <String, VatStatement>{};
  final _projectDashboards = <String, Dashboard>{};
  final _projectPeriodicReports = <String, PeriodicReports>{};
  late final _reportFiles = ReportFiles(widget.session, widget.capture);

  late final _router = GoRouter(
    initialLocation: HomeScreen.landingOf(widget.session),
    refreshListenable: widget.session,
    redirect: (context, state) => _redirect(state.matchedLocation),
    routes: [
      GoRoute(path: ProjectsScreen.path, builder: (context, state) => ProjectsScreen(projects: _projects, session: widget.session, notifications: _notifications)),
      GoRoute(path: NotificationsScreen.path, builder: (context, state) => NotificationsScreen(notifications: _notifications, projects: _projects)),
      GoRoute(
        path: ShareScreen.path,
        builder: (context, state) => ShareScreen(
          file: _shared,
          capture: widget.capture,
          projects: _projects,
          itemsOf: _offeredItemsOf,
          entriesOf: (projectId) => _projectAttachable.putIfAbsent(projectId, () => AttachableEntries(widget.session, projectId)),
          attachmentsOf: _attachmentsOf,
          onDone: _letGoOfShared,
        ),
      ),
      GoRoute(path: SignInScreen.path, builder: (context, state) => SignInScreen(session: widget.session, language: widget.language)),
      GoRoute(path: ChangePasswordScreen.path, builder: (context, state) => ChangePasswordScreen(session: widget.session)),
      GoRoute(path: MyAccountScreen.path, builder: (context, state) => MyAccountScreen(language: widget.language, session: widget.session)),
      GoRoute(path: SettingsScreen.path, builder: (context, state) => SettingsScreen(session: widget.session, project: Project.none())),
      GoRoute(path: SettingsScreen.projectPath, builder: (context, state) => SettingsScreen(session: widget.session, project: state.extra! as Project)),
      GoRoute(path: NewProjectScreen.path, builder: (context, state) => NewProjectScreen(projects: _projects)),
      GoRoute(
        path: HomeScreen.path,
        builder: (context, state) => HomeScreen(projectId: state.pathParameters['projectId'] ?? '', projects: _projects, accounts: _accountsOf(state.pathParameters['projectId'] ?? ''), outbox: _outbox, sync: _sync, entries: _entriesOf(state.pathParameters['projectId'] ?? ''), notifications: _notifications, dashboard: _dashboardOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: ApprovalsScreen.path,
        builder: (context, state) => ApprovalsScreen(project: state.extra! as Project, approvals: _approvalsOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: AttachmentScreen.path,
        builder: (context, state) => AttachmentScreen(
          projectId: state.pathParameters['projectId'] ?? '',
          attachmentId: state.pathParameters['attachmentId'] ?? '',
          fileName: state.uri.queryParameters['name'] ?? '',
          contentType: state.extra as String? ?? '',
          session: widget.session,
          capture: widget.capture,
        ),
      ),
      GoRoute(path: WaitingScreen.path, builder: (context, state) => WaitingScreen(projectId: state.pathParameters['projectId'] ?? '', outbox: _outbox)),
      GoRoute(path: NewProjectScreen.registerPath, builder: (context, state) => NewProjectScreen(projects: _projects, isPublic: true)),
      GoRoute(path: RegisteredProjectsScreen.path, builder: (context, state) => RegisteredProjectsScreen(projects: _registered)),
      GoRoute(
        path: UsersScreen.path,
        builder: (context, state) => UsersScreen(users: _usersOf(state.pathParameters['projectId'] ?? ''), projectName: state.extra as String? ?? ''),
      ),
      GoRoute(path: NewUserScreen.path, builder: (context, state) => NewUserScreen(users: _usersOf(state.pathParameters['projectId'] ?? ''))),
      GoRoute(
        path: UserPermissionsScreen.path,
        builder: (context, state) => UserPermissionsScreen(
          userId: state.pathParameters['userId'] ?? '',
          users: _usersOf(state.pathParameters['projectId'] ?? ''),
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
        builder: (context, state) => AccountsScreen(
          project: state.extra! as Project,
          accounts: _accountsOf(state.pathParameters['projectId'] ?? ''),
          members: _membersOf(state.pathParameters['projectId'] ?? ''),
          transfers: _transfersOf(state.pathParameters['projectId'] ?? ''),
          reconciliations: _reconciliationsOf(state.pathParameters['projectId'] ?? ''),
        ),
      ),
      GoRoute(
        path: TransferScreen.path,
        builder: (context, state) => TransferScreen(
          project: state.extra! as Project,
          accounts: _accountsOf(state.pathParameters['projectId'] ?? ''),
          transfers: _transfersOf(state.pathParameters['projectId'] ?? ''),
          attachments: _attachmentsOf(state.pathParameters['projectId'] ?? ''),
          capture: widget.capture,
        ),
      ),
      GoRoute(path: RevenueScreen.path, builder: (context, state) => RevenueScreen(project: state.extra! as Project, revenues: _revenuesOf(state.pathParameters['projectId'] ?? ''))),
      GoRoute(
        path: RevenueFormScreen.path,
        builder: (context, state) => RevenueFormScreen(
          project: state.extra! as Project,
          revenues: _revenuesOf(state.pathParameters['projectId'] ?? ''),
          items: _revenueItemsOf(state.pathParameters['projectId'] ?? ''),
          accounts: _accountsOf(state.pathParameters['projectId'] ?? ''),
          attachments: _attachmentsOf(state.pathParameters['projectId'] ?? ''),
          capture: widget.capture,
        ),
      ),
      GoRoute(
        path: SalesInvoiceScreen.path,
        builder: (context, state) => SalesInvoiceScreen(project: state.extra! as Project, revenues: _revenuesOf(state.pathParameters['projectId'] ?? ''), accounts: _accountsOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: ReportsScreen.path,
        builder: (context, state) => ReportsScreen(
          project: state.extra! as Project,
          dashboard: _dashboardOf(state.pathParameters['projectId'] ?? ''),
          periodicReports: _projectPeriodicReports.putIfAbsent(state.pathParameters['projectId'] ?? '', () => PeriodicReports(widget.session, state.pathParameters['projectId'] ?? '')),
          nextReport: NextReport(widget.session, state.pathParameters['projectId'] ?? ''),
          files: _reportFiles,
        ),
      ),
      GoRoute(
        path: PeriodicReportScreen.path,
        builder: (context, state) => PeriodicReportScreen(
          project: state.extra! as Project,
          number: int.parse(state.pathParameters['number'] ?? '0'),
          report: PeriodicReport(widget.session, state.pathParameters['projectId'] ?? '', int.parse(state.pathParameters['number'] ?? '0')),
          files: _reportFiles,
        ),
      ),
      GoRoute(
        path: ItemReportScreen.path,
        builder: (context, state) => ItemReportScreen(
          project: state.extra! as Project,
          itemId: state.pathParameters['itemId'] ?? '',
          report: ItemReport(widget.session, state.pathParameters['projectId'] ?? '', state.pathParameters['itemId'] ?? ''),
          files: _reportFiles,
        ),
      ),
      GoRoute(
        path: VatStatementScreen.path,
        builder: (context, state) => VatStatementScreen(
          project: state.extra! as Project,
          statement: _projectVat.putIfAbsent(state.pathParameters['projectId'] ?? '', () => VatStatement(widget.session, state.pathParameters['projectId'] ?? '')),
          files: _reportFiles,
        ),
      ),
      GoRoute(
        path: ReconcileScreen.path,
        builder: (context, state) => ReconcileScreen(project: state.extra! as Project, reconciliations: _reconciliationsOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: PartnersScreen.path,
        builder: (context, state) => PartnersScreen(project: state.extra! as Project, partners: _partnersOf(state.pathParameters['projectId'] ?? ''), members: _membersOf(state.pathParameters['projectId'] ?? ''), capital: _capitalOf(state.pathParameters['projectId'] ?? '')),
      ),
      GoRoute(
        path: MovementsScreen.path,
        builder: (context, state) => MovementsScreen(
          project: state.extra! as Project,
          partnerName: state.uri.queryParameters['name'] ?? '',
          movements: CapitalMovements(widget.session, state.pathParameters['projectId'] ?? '', state.pathParameters['partnerId'] ?? ''),
          capital: _capitalOf(state.pathParameters['projectId'] ?? ''),
        ),
      ),
      GoRoute(
        path: DocumentsScreen.path,
        builder: (context, state) => DocumentsScreen(
          project: state.extra! as Project,
          documents: Documents(widget.session, state.pathParameters['projectId'] ?? ''),
          capture: widget.capture,
        ),
      ),
      GoRoute(
        path: LiquidationScreen.path,
        builder: (context, state) => LiquidationScreen(
          project: state.extra! as Project,
          liquidation: Liquidation(widget.session, state.pathParameters['projectId'] ?? ''),
          projects: _projects,
          accounts: _accountsOf(state.pathParameters['projectId'] ?? ''),
          partnersOf: _partnersOf,
          accountsOf: _accountsOf,
          items: _offeredItemsOf(state.pathParameters['projectId'] ?? '', ItemType.purchases),
          revenueItems: _revenueItemsOf(state.pathParameters['projectId'] ?? ''),
          capture: widget.capture,
        ),
      ),
      GoRoute(
        path: CapitalMoveScreen.path,
        builder: (context, state) => CapitalMoveScreen(
          project: state.extra! as Project,
          projects: _projects,
          capital: _capitalOf(state.pathParameters['projectId'] ?? ''),
          partners: _partnersOf(state.pathParameters['projectId'] ?? ''),
          accounts: _accountsOf(state.pathParameters['projectId'] ?? ''),
          partnersOf: _partnersOf,
          accountsOf: _accountsOf,
          attachments: _attachmentsOf(state.pathParameters['projectId'] ?? ''),
          capture: widget.capture,
          sharedFile: state.uri.queryParameters.containsKey('shared') ? _shared : PickedFile.none(),
        ),
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
      GoRoute(path: AddExpenseScreen.path, builder: (context, state) => _addExpenseScreen(state.pathParameters['projectId'] ?? '', state.extra! as Project, state.uri.queryParameters)),
      GoRoute(path: ContractorPaymentScreen.path, builder: (context, state) => _contractorPaymentScreen(state.pathParameters['projectId'] ?? '', state.extra! as Project, state.uri.queryParameters)),
      GoRoute(
        path: EntriesScreen.path,
        builder: (context, state) => EntriesScreen(project: state.extra! as Project, entries: _entriesOf(state.pathParameters['projectId'] ?? ''), openEntryId: state.uri.queryParameters['entry'] ?? ''),
      ),
      GoRoute(
        path: ItemTablesScreen.path,
        builder: (context, state) => ItemTablesScreen(
          itemId: state.pathParameters['itemId'] ?? '',
          project: state.extra! as Project,
          categories: _categoriesOf(state.pathParameters['projectId'] ?? ''),
          tables: ItemTables(widget.session, state.pathParameters['projectId'] ?? '', state.pathParameters['itemId'] ?? ''),
        ),
      ),
    ],
  );

  Users _usersOf(String projectId) => _projectUsers.putIfAbsent(projectId, () => Users(widget.session, projectId));


  Categories _categoriesOf(String projectId) => _projectCategories.putIfAbsent(projectId, () => Categories(widget.session, projectId));

  PaymentMethods _paymentMethodsOf(String projectId) => _projectPaymentMethods.putIfAbsent(projectId, () => PaymentMethods(widget.session, projectId));

  Accounts _accountsOf(String projectId) => _projectAccounts.putIfAbsent(projectId, () => Accounts(widget.session, projectId));

  Transfers _transfersOf(String projectId) => _projectTransfers.putIfAbsent(projectId, () => Transfers(widget.session, projectId));

  Reconciliations _reconciliationsOf(String projectId) => _projectReconciliations.putIfAbsent(projectId, () => Reconciliations(widget.session, projectId));

  Dashboard _dashboardOf(String projectId) => _projectDashboards.putIfAbsent(projectId, () => Dashboard(widget.session, projectId));

  Revenues _revenuesOf(String projectId) => _projectRevenues.putIfAbsent(projectId, () => Revenues(widget.session, projectId));

  Capital _capitalOf(String projectId) => _projectCapital.putIfAbsent(projectId, () => Capital(widget.session, projectId));

  Members _membersOf(String projectId) => _projectMembers.putIfAbsent(projectId, () => Members(widget.session, projectId));

  Partners _partnersOf(String projectId) => _projectPartners.putIfAbsent(projectId, () => Partners(widget.session, projectId));

  Suppliers _suppliersOf(String projectId) => _projectSuppliers.putIfAbsent(projectId, () => Suppliers(widget.session, projectId));

  /// Every revenue item of [projectId]: entering revenue of any kind offers them all, and the item chosen says which kind it is.
  OfferedItems _revenueItemsOf(String projectId) => _offeredItemsOf(projectId, ItemType.otherRevenue);

  OfferedItems _offeredItemsOf(String projectId, ItemType type) => _offeredItemLists.putIfAbsent('$projectId/${type.name}', () => OfferedItems(widget.session, projectId, type));

  Contracts _contractsOf(String projectId) => _projectContracts.putIfAbsent(projectId, () => Contracts(widget.session, projectId));

  Attachments _attachmentsOf(String projectId) => _projectAttachments.putIfAbsent(projectId, () => Attachments(widget.session, projectId));

  Expenses _expensesOf(String projectId) => _projectExpenses.putIfAbsent(projectId, () => Expenses(widget.session, projectId, _outbox, _entriesOf(projectId)));

  ProjectEntries _entriesOf(String projectId) => _projectEntries.putIfAbsent(projectId, () => ProjectEntries(widget.session, projectId));

  Approvals _approvalsOf(String projectId) => _projectApprovals.putIfAbsent(projectId, () => Approvals(widget.session, projectId));

  OfferedAccounts _offeredAccountsOf(String projectId) => _projectOfferedAccounts.putIfAbsent(projectId, () => OfferedAccounts(widget.session, projectId));

  ContractorPaymentScreen _contractorPaymentScreen(String projectId, Project project, Map<String, String> query) => ContractorPaymentScreen(
    editingId: query['entry'] ?? '',
    rejectionReason: query['reason'] ?? '',
    items: _offeredItemsOf(projectId, ItemType.contractorPayments),
    project: project,
    expenses: _expensesOf(projectId),
    contracts: _contractsOf(projectId),
    accounts: _offeredAccountsOf(projectId),
    paymentMethods: _paymentMethodsOf(projectId),
    columnsOf: (itemId) => _columnsAt(Columns.itemPath(projectId, itemId)),
    attachments: _attachmentsOf(projectId),
    capture: widget.capture,
  );

  AddExpenseScreen _addExpenseScreen(String projectId, Project project, Map<String, String> query) => AddExpenseScreen(
    sharedFile: query.containsKey('shared') ? _shared : PickedFile.none(),
    editingId: query['entry'] ?? '',
    rejectionReason: query['reason'] ?? '',
    project: project,
    expenses: _expensesOf(projectId),
    items: _offeredItemsOf(projectId, ItemType.purchases),
    accounts: _offeredAccountsOf(projectId),
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
    if (location != SignInScreen.path) {
      return null;
    }
    return _shared.isNone ? HomeScreen.landingOf(session) : ShareScreen.path;
  }

  void _openShared(PickedFile file) {
    if (!file.isNone) {
      _shared = file;
      _router.go(ShareScreen.path);
    }
  }

  void _letGoOfShared() {
    _shared = PickedFile.none();
    _router.go(HomeScreen.landingOf(widget.session));
  }

  @override
  void initState() {
    super.initState();
    unawaited(_outbox.start());
    _sharing = widget.capture.shared().listen(_openShared);
  }

  @override
  void dispose() {
    unawaited(_sharing.cancel());
    _router.dispose();
    _outbox.dispose();
    _projects.dispose();
    _registered.dispose();
    _notifications.dispose();
    super.dispose();
  }

  /// Loads the words again: the no-network screen's retry, and newer words fetched in the background (findings row 133).
  void _reloadWords() {
    if (mounted) {
      setState(() => _wordsAttempt++);
    }
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
          WordsDelegate(_wordsAttempt, onRefreshed: _reloadWords),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [for (final language in Words.languages) Locale(language)],
        theme: ThemeData(colorSchemeSeed: const Color(0xFF0E6B68), fontFamily: 'IBMPlexSansArabic'),
        builder: (context, child) => Words.of(context).isEmpty
            ? NoWordsScreen(onRetry: _reloadWords)
            : child ?? const SizedBox.shrink(),
      ),
    );
  }
}
