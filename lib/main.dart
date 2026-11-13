import 'dart:async';
import 'documents/documents.dart';
import 'documents/documents_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'accounts/accounts.dart';
import 'accounts/accounts_screen.dart';
import 'accounts/offered_accounts.dart';
import 'accounts/reconcile_screen.dart';
import 'accounts/reconciliation.dart';
import 'api.dart';
import 'attachments/attachments.dart';
import 'attachments/invoice_capture.dart';
import 'attachments/picked_file.dart';
import 'auth/change_password_screen.dart';
import 'auth/session.dart';
import 'auth/sign_in_screen.dart';
import 'contracts/contracts.dart';
import 'contracts/contracts_screen.dart';
import 'home/home_screen.dart';
import 'partners/capital.dart';
import 'partners/capital_movements.dart';
import 'partners/movements_screen.dart';
import 'partners/partners.dart';
import 'partners/partners_screen.dart';
import 'partners/partner_history.dart';
import 'partners/partner_history_screen.dart';
import 'approvals/approvals.dart';
import 'approvals/approvals_screen.dart';
import 'approvals/approval_history.dart';
import 'approvals/approval_history_screen.dart';
import 'attachments/attachment_screen.dart';
import 'entries/entry_recording.dart';
import 'entries/add_entry_screen.dart';
import 'entries/entries_screen.dart';
import 'entries/entry_tables.dart';
import 'entries/newest_entries.dart';
import 'entries/opened_entry.dart';
import 'entries/project_entries.dart';
import 'notifications/notifications.dart';
import 'notifications/notifications_screen.dart';
import 'offline/outbox.dart';
import 'offline/project_sync.dart';
import 'offline/waiting_screen.dart';
import 'projects/members.dart';
import 'reports/summary.dart';
import 'reports/item_report.dart';
import 'reports/item_report_screen.dart';
import 'reports/item_reports_screen.dart';
import 'reports/periodic_report_screen.dart';
import 'reports/periodic_reports.dart';
import 'reports/report_files.dart';
import 'reports/reports_screen.dart';
import 'reports/vat_statement_screen.dart';
import 'projects/new_project_screen.dart';
import 'projects/project_info_screen.dart';
import 'projects/projects.dart';
import 'projects/projects_screen.dart';
import 'projects/registered_projects.dart';
import 'projects/registered_projects_screen.dart';
import 'projects/project.dart';
import 'settings/payment_methods.dart';
import 'settings/payment_methods_screen.dart';
import 'settings/shared_settings_screen.dart';
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
import 'config/local_config.dart';
import 'entries/entry_link_screen.dart';
import 'ui/app_theme.dart';
import 'accounts/account_history.dart';
import 'accounts/account_history_screen.dart';
import 'users/my_permissions_screen.dart';
import 'entries/searched_entries.dart';

/// Starts the app with the session and the language kept from an earlier start, if any. An app built without its environment's config
/// file stops here, rather than calling an address nobody chose.
Future<void> main() async {
  if (apiBaseUrl.isEmpty) {
    throw StateError('No API address: build with --dart-define-from-file=config/<environment>.json, which sets API_BASE_URL.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  final language = AppLanguage();
  final localConfig = LocalConfig();
  await config.restore();
  unawaited(config.refresh());
  await session.restore();
  await language.restore();
  await localConfig.restore();
  runApp(RedixApp(session: session, language: language, localConfig: localConfig));
}

/// The app: its theme, its languages, and its screens. Without a session every screen leads to sign-in; with a temporary password, to the password change.
class RedixApp extends StatefulWidget {
  /// The app, signed in through [session], shown in [language], keeping this phone's choices in [localConfig], and reaching the phone's camera and files through [capture].
  const RedixApp({super.key, required this.session, required this.language, required this.localConfig, this.capture = const InvoiceCapture()});

  /// The signed-in session the screens depend on.
  final Session session;

  /// The language the user chose; the phone's while none is chosen.
  final AppLanguage language;

  /// What this phone keeps of its own choices.
  final LocalConfig localConfig;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  @override
  State<RedixApp> createState() => _RedixAppState();
}

class _RedixAppState extends State<RedixApp> {
  var _wordsAttempt = 0;
  var _shared = PickedFile.none();

  /// A shared entry's link opened before signing in, to open once signed in (redix-app #83, R8); empty for none.
  var _afterSignIn = '';
  late final StreamSubscription<PickedFile> _sharing;

  /// Renews the session each time the app comes back to the screen, so it learns soon what changed while it was away (redix-api #126 R6).
  late final AppLifecycleListener _lifecycle;
  late final _projects = Projects(widget.session);
  late final _outbox = Outbox(widget.session, widget.session.store);
  late final _sync = ProjectSync(widget.session);
  late final _registered = RegisteredProjects(widget.session);
  late final _notifications = Notifications(widget.session);
  late final _usersOf = _kept((projectId) => Users(widget.session, projectId));
  late final _categoriesOf = _kept((projectId) => Categories(widget.session, projectId));
  late final _paymentMethodsOf = _kept((projectId) => PaymentMethods(widget.session, projectId));
  late final _accountsOf = _kept((projectId) => Accounts(widget.session, projectId));
  late final _reconciliationsOf = _kept((projectId) => Reconciliations(widget.session, projectId));
  late final _historyOf = _kept((projectId) => AccountHistory(widget.session, projectId));
  late final _partnerHistoryOf = _kept((projectId) => PartnerHistory(widget.session, projectId));
  late final _approvalHistoryOf = _kept((projectId) => ApprovalHistory(widget.session, projectId));
  late final _summaryOf = _kept((projectId) => Summary(widget.session, projectId));
  late final _capitalOf = _kept((projectId) => Capital(widget.session, projectId));
  late final _membersOf = _kept((projectId) => Members(widget.session, projectId));
  late final _partnersOf = _kept((projectId) => Partners(widget.session, projectId));
  late final _suppliersOf = _kept((projectId) => Suppliers(widget.session, projectId));
  late final _contractsOf = _kept((projectId) => Contracts(widget.session, projectId));
  late final _attachmentsOf = _kept((projectId) => Attachments(widget.session, projectId));
  late final _recordingOf = _kept((projectId) => EntryRecording(widget.session, projectId, _outbox));
  late final _entriesOf = _kept((projectId) => ProjectEntries(widget.session, projectId));
  late final _newestEntriesOf = _kept((projectId) => NewestEntries(widget.session, projectId, widget.localConfig));
  late final _searchedEntriesOf = _kept((projectId) => SearchedEntries(widget.session, projectId, widget.localConfig));
  late final _openedEntryOf = _kept((projectId) => OpenedEntry(widget.session, projectId));
  late final _approvalsOf = _kept((projectId) => Approvals(widget.session, projectId));
  late final _offeredAccountsOf = _kept((projectId) => OfferedAccounts(widget.session, projectId));
  late final _columnsAt = _kept((path) => Columns(widget.session, path));
  late final _periodicReportsOf = _kept((projectId) => PeriodicReports(widget.session, projectId));
  late final _nextReportOf = _kept((projectId) => NextReport(widget.session, projectId));
  late final _documentsOf = _kept((projectId) => Documents(widget.session, projectId));
  late final _attachableOf = _kept((projectId) => AttachableEntries(widget.session, projectId));
  late final _entryTablesOf = _kept((projectId) => EntryTables(widget.session, projectId));
  final _offeredItemLists = <String, OfferedItems>{};
  final _periodicReports = <String, PeriodicReport>{};
  final _itemReports = <String, ItemReport>{};
  final _partnerMovements = <String, CapitalMovements>{};
  final _itemTables = <String, ItemTables>{};
  late final _reportFiles = ReportFiles(widget.session, widget.capture);

  late final _router = GoRouter(
    initialLocation: HomeScreen.landingOf(widget.session),
    refreshListenable: widget.session.access,
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
          tablesOf: _entryTablesOf,
          entriesOf: _attachableOf,
          attachmentsOf: _attachmentsOf,
          onDone: _letGoOfShared,
        ),
      ),
      GoRoute(path: SignInScreen.path, builder: (context, state) => SignInScreen(session: widget.session, language: widget.language)),
      GoRoute(path: ChangePasswordScreen.path, builder: (context, state) => ChangePasswordScreen(session: widget.session)),
      GoRoute(
        path: SharedSettingsScreen.path,
        builder: (context, state) => SharedSettingsScreen(
          session: widget.session,
          projects: _projects,
          project: switch (state.extra) {
            final Project project => project,
            _ => Project.none(),
          },
          language: widget.language,
          localConfig: widget.localConfig,
        ),
      ),
      GoRoute(path: ProjectInfoScreen.path, builder: (context, state) => ProjectInfoScreen(project: state.extra! as Project, projects: _projects)),
      GoRoute(path: MyPermissionsScreen.path, builder: (context, state) => MyPermissionsScreen(project: state.extra! as Project, projects: _projects, partners: _partnersOf(state.projectId))),
      GoRoute(path: NewProjectScreen.path, builder: (context, state) => NewProjectScreen(projects: _projects)),
      GoRoute(
        path: HomeScreen.path,
        builder: (context, state) => HomeScreen(projectId: state.projectId, projects: _projects, accounts: _accountsOf(state.projectId), outbox: _outbox, sync: _sync, entries: _newestEntriesOf(state.projectId), notifications: _notifications, summary: _summaryOf(state.projectId), localConfig: widget.localConfig),
      ),
      GoRoute(
        path: ApprovalsScreen.path,
        builder: (context, state) => ApprovalsScreen(project: state.extra! as Project, approvals: _approvalsOf(state.projectId), focusEntryId: state.uri.queryParameters['entry'] ?? ''),
      ),
      GoRoute(
        path: EntryLinkScreen.path,
        builder: (context, state) => EntryLinkScreen(projectId: state.projectId, entryId: state.pathParameters['entryId'] ?? '', projects: _projects, entriesOf: _entriesOf),
      ),
      GoRoute(
        path: AttachmentScreen.path,
        builder: (context, state) => AttachmentScreen(
          projectId: state.projectId,
          attachmentId: state.pathParameters['attachmentId'] ?? '',
          fileName: state.uri.queryParameters['name'] ?? '',
          contentType: state.extra as String? ?? '',
          session: widget.session,
          capture: widget.capture,
        ),
      ),
      GoRoute(path: WaitingScreen.path, builder: (context, state) => WaitingScreen(projectId: state.projectId, outbox: _outbox)),
      GoRoute(path: NewProjectScreen.registerPath, builder: (context, state) => NewProjectScreen(projects: _projects, isPublic: true)),
      GoRoute(path: RegisteredProjectsScreen.path, builder: (context, state) => RegisteredProjectsScreen(projects: _registered)),
      GoRoute(
        path: UsersScreen.path,
        builder: (context, state) => UsersScreen(users: _usersOf(state.projectId), projectName: (state.extra! as Project).name),
      ),
      GoRoute(path: NewUserScreen.path, builder: (context, state) => NewUserScreen(users: _usersOf(state.projectId), partners: _partnersOf(state.projectId))),
      GoRoute(
        path: UserPermissionsScreen.path,
        builder: (context, state) => UserPermissionsScreen(
          userId: state.pathParameters['userId'] ?? '',
          users: _usersOf(state.projectId),
          partners: _partnersOf(state.projectId),
          projectName: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: CategoriesScreen.path,
        builder: (context, state) => CategoriesScreen(categories: _categoriesOf(state.projectId), project: state.extra! as Project),
      ),
      GoRoute(path: ItemColumnsScreen.path, builder: (context, state) => _itemColumnsScreen(state.projectId, state.pathParameters['itemId'] ?? '', state.extra! as Project)),
      GoRoute(
        path: PaymentMethodsScreen.path,
        builder: (context, state) => PaymentMethodsScreen(project: state.extra! as Project, paymentMethods: _paymentMethodsOf(state.projectId)),
      ),
      GoRoute(
        path: AccountsScreen.path,
        builder: (context, state) => AccountsScreen(
          project: state.extra! as Project,
          accounts: _accountsOf(state.projectId),
          reconciliations: _reconciliationsOf(state.projectId),
          members: _membersOf(state.projectId),
        ),
      ),
      GoRoute(
        path: AccountHistoryScreen.path,
        builder: (context, state) => AccountHistoryScreen(project: state.extra! as Project, history: _historyOf(state.projectId), accounts: _accountsOf(state.projectId)),
      ),
      GoRoute(
        path: ApprovalHistoryScreen.path,
        builder: (context, state) => ApprovalHistoryScreen(project: state.extra! as Project, history: _approvalHistoryOf(state.projectId)),
      ),
      GoRoute(
        path: PartnerHistoryScreen.path,
        builder: (context, state) => PartnerHistoryScreen(project: state.extra! as Project, history: _partnerHistoryOf(state.projectId), partners: _partnersOf(state.projectId)),
      ),
      GoRoute(
        path: ReportsScreen.path,
        builder: (context, state) => ReportsScreen(
          project: state.extra! as Project,
          periodicReports: _periodicReportsOf(state.projectId),
          nextReport: _nextReportOf(state.projectId),
        ),
      ),
      GoRoute(
        path: ItemReportsScreen.path,
        builder: (context, state) => ItemReportsScreen(
          project: state.extra! as Project,
          summary: _summaryOf(state.projectId),
          side: SummarySide.values.firstWhere((side) => side.name == state.pathParameters['side'], orElse: () => SummarySide.expenses),
        ),
      ),
      GoRoute(
        path: PeriodicReportScreen.path,
        builder: (context, state) => PeriodicReportScreen(
          project: state.extra! as Project,
          number: int.parse(state.pathParameters['number'] ?? '0'),
          report: _periodicReports.putIfAbsent(state.uri.path, () => PeriodicReport(widget.session, state.projectId, int.parse(state.pathParameters['number'] ?? '0'))),
          files: _reportFiles,
        ),
      ),
      GoRoute(
        path: ItemReportScreen.path,
        builder: _itemReportScreen,
      ),
      GoRoute(
        path: ItemReportScreen.contractPath,
        builder: _itemReportScreen,
      ),
      GoRoute(
        path: VatStatementScreen.path,
        builder: (context, state) => VatStatementScreen(
          project: state.extra! as Project,
          files: _reportFiles,
        ),
      ),
      GoRoute(
        path: ReconcileScreen.path,
        builder: (context, state) => ReconcileScreen(project: state.extra! as Project, reconciliations: _reconciliationsOf(state.projectId)),
      ),
      GoRoute(
        path: PartnersScreen.path,
        builder: (context, state) => PartnersScreen(
          project: state.extra! as Project,
          partners: _partnersOf(state.projectId),
          members: _membersOf(state.projectId),
          capital: _capitalOf(state.projectId),
        ),
      ),
      GoRoute(
        path: MovementsScreen.path,
        builder: (context, state) => MovementsScreen(
          project: state.extra! as Project,
          partnerName: state.uri.queryParameters['name'] ?? '',
          movements: _partnerMovements.putIfAbsent(state.uri.path, () => CapitalMovements(widget.session, state.projectId, state.pathParameters['partnerId'] ?? '')),
          capital: _capitalOf(state.projectId),
        ),
      ),
      GoRoute(
        path: DocumentsScreen.path,
        builder: (context, state) => DocumentsScreen(
          project: state.extra! as Project,
          documents: _documentsOf(state.projectId),
          capture: widget.capture,
          files: _reportFiles,
        ),
      ),
      GoRoute(
        path: SuppliersScreen.path,
        builder: (context, state) => SuppliersScreen(
          project: state.extra! as Project,
          suppliers: _suppliersOf(state.projectId),
          items: _offeredItemsOf(state.projectId, ItemType.purchases),
        ),
      ),
      GoRoute(
        path: ContractsScreen.path,
        builder: (context, state) => ContractsScreen(
          project: state.extra! as Project,
          contracts: _contractsOf(state.projectId),
          suppliers: _suppliersOf(state.projectId),
          items: _offeredItemsOf(state.projectId, ItemType.contractorPayments),
          attachments: _attachmentsOf(state.projectId),
          capture: widget.capture,
          files: _reportFiles,
        ),
      ),
      GoRoute(path: AddEntryScreen.path, builder: (context, state) => _addEntryScreen(state.projectId, state.extra! as Project, state.uri.queryParameters)),
      GoRoute(
        path: EntriesScreen.path,
        builder: (context, state) => EntriesScreen(project: state.extra! as Project, entries: _searchedEntriesOf(state.projectId), startsSearching: state.uri.queryParameters.containsKey('search')),
      ),
      GoRoute(
        path: ItemTablesScreen.path,
        builder: (context, state) => ItemTablesScreen(
          itemId: state.pathParameters['itemId'] ?? '',
          project: state.extra! as Project,
          categories: _categoriesOf(state.projectId),
          tables: _itemTables.putIfAbsent(state.uri.path, () => ItemTables(widget.session, state.projectId, state.pathParameters['itemId'] ?? '')),
        ),
      ),
    ],
  );

  /// The items of [projectId] offered for [type]: an expense of that type, revenue of any kind, or a partner's capital item.
  OfferedItems _offeredItemsOf(String projectId, ItemType type) => _offeredItemLists.putIfAbsent('$projectId/${type.name}', () => OfferedItems(widget.session, projectId, type));

  AddEntryScreen _addEntryScreen(String projectId, Project project, Map<String, String> query) => AddEntryScreen(
    readAgain: () => Future.wait([_newestEntriesOf(projectId).load(), _searchedEntriesOf(projectId).load(), _summaryOf(projectId).load(), _accountsOf(projectId).load()]),
    sharedFile: query.containsKey('shared') ? _shared : PickedFile.none(),
    editingId: query['entry'] ?? '',
    isReading: query.containsKey('read'),
    rejectionReason: query['reason'] ?? '',
    project: project,
    recording: _recordingOf(projectId),
    tables: _entryTablesOf(projectId),
    contracts: _contractsOf(projectId),
    accounts: _offeredAccountsOf(projectId),
    paymentMethods: _paymentMethodsOf(projectId),
    suppliers: _suppliersOf(projectId),
    columnsOf: (itemId) => _columnsAt(Columns.itemPath(projectId, itemId)),
    attachments: _attachmentsOf(projectId),
    capture: widget.capture,
    opened: _openedEntryOf(projectId),
    approvals: _approvalsOf(projectId),
    projectAccounts: _accountsOf(projectId),
  );

  /// The report at the route's own address, an item's or one contract's, whose API address is the same (Muteb, 12 Nov 2026).
  ItemReportScreen _itemReportScreen(BuildContext context, GoRouterState state) => ItemReportScreen(
    project: state.extra! as Project,
    address: state.uri.path,
    report: _itemReports.putIfAbsent(state.uri.path, () => ItemReport(widget.session, state.uri.path)),
    files: _reportFiles,
  );

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
      if (location == SignInScreen.path || location == NewProjectScreen.registerPath) {
        return null;
      }
      _afterSignIn = location;
      return SignInScreen.path;
    }
    if (session.mustChangePassword) {
      return location == ChangePasswordScreen.path ? null : ChangePasswordScreen.path;
    }
    if (location != SignInScreen.path) {
      return null;
    }
    final asked = _afterSignIn;
    _afterSignIn = '';
    return _shared.isNone ? (EntryLinkScreen.isLink(asked) ? asked : HomeScreen.landingOf(session)) : ShareScreen.path;
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
    _lifecycle = AppLifecycleListener(onResume: widget.session.renew);
  }

  @override
  void dispose() {
    unawaited(_sharing.cancel());
    _lifecycle.dispose();
    _router.dispose();
    _outbox.dispose();
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
      listenable: Listenable.merge([widget.language, widget.localConfig]),
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
        theme: appThemeOf(Brightness.light),
        darkTheme: appThemeOf(Brightness.dark),
        themeMode: widget.localConfig.themeMode,
        builder: (context, child) => Words.of(context).isEmpty
            ? NoWordsScreen(onRetry: _reloadWords)
            : child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// What [make] builds for a key, a project's id or a route, built the first time it is asked for and then kept.
T Function(String) _kept<T>(T Function(String key) make) {
  final built = <String, T>{};
  return (key) => built.putIfAbsent(key, () => make(key));
}

extension on GoRouterState {
  /// The project the route is about; empty on a route that names none.
  String get projectId => pathParameters['projectId'] ?? '';
}
