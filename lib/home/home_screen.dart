import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/accounts.dart';
import '../accounts/accounts_screen.dart';
import '../accounts/my_custody.dart';
import '../auth/session.dart';
import '../contractor_payments/contractor_payment_screen.dart';
import '../contracts/contracts_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../partners/partners_screen.dart';
import '../partners/liquidation_screen.dart';
import '../projects/blueprints_screen.dart';
import '../reports/reports_screen.dart';
import '../revenue/revenue_screen.dart';
import '../approvals/approvals_screen.dart';
import '../entries/my_entries_summary.dart';
import '../entries/project_entries.dart';
import '../notifications/notifications.dart';
import '../notifications/notifications_bell.dart';
import '../offline/outbox.dart';
import '../offline/project_sync.dart';
import '../offline/waiting_screen.dart';
import '../projects/add_unit_dialog.dart';
import '../reports/dashboard.dart';
import '../reports/item_report_screen.dart';
import 'dashboard_card.dart';
import '../projects/project.dart';
import '../projects/project_card.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../settings/payment_methods_screen.dart';
import '../settings/settings_screen.dart';
import '../structure/categories_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/name_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../users/users_screen.dart';
import '../words/words.dart';

/// The home of the open project (UC-010): the project, with what the user's roles allow in it (AC-36.2). Each later use case adds to it.
class HomeScreen extends StatefulWidget {
  /// The home of the project [projectId], one of [projects], with [accounts], its accounts.
  const HomeScreen({super.key, required this.projectId, required this.projects, required this.accounts, required this.outbox, required this.sync, required this.entries, required this.notifications, required this.dashboard});

  /// Its figures at a glance.
  final Dashboard dashboard;

  /// What the user was told.
  final Notifications notifications;

  /// The project's entries.
  final ProjectEntries entries;

  /// What waits on this phone for the network.
  final Outbox outbox;

  /// What keeps the project's lists on the phone.
  final ProjectSync sync;

  /// The open project.
  final String projectId;

  /// The projects, among them this one.
  final Projects projects;

  /// Its accounts, among them what the signed-in user holds.
  final Accounts accounts;

  /// The screen's route.
  static const path = '/projects/:projectId';

  /// The project's name.
  static const titleKey = Key('home.title');

  /// The button that opens Settings.
  static const settingsKey = Key('home.settings');

  /// The line that says the project could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The button that reads it again.
  static const retryKey = ApiListBody.retryKey;

  /// The unit's name, in the Add unit dialog.
  static const unitNameKey = Key('home.unitName');

  /// The button that adds the unit, in the Add unit dialog.
  static const saveUnitKey = ChangeDialog.saveKey;

  /// The line that says why the unit was refused, in the Add unit dialog.
  static const unitMessageKey = ChangeDialog.messageKey;

  /// The project's name, in the close question.
  static const closeNameKey = ConfirmDialog.subjectKey;

  /// What closing means, in the close question.
  static const closeExplainKey = ConfirmDialog.explanationKey;

  /// The button that closes the project, in the close question.
  static const confirmCloseKey = ConfirmDialog.confirmKey;

  /// The button that keeps the project running, in the close question.
  static const cancelCloseKey = ConfirmDialog.cancelKey;

  /// The route of the home of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId';

  /// Where [session] lands at app start and at sign-in, and nowhere else, so Switch project is never bounced (AC-37.1).
  static String landingOf(Session session) => session.opensDefaultProject ? pathOf(session.defaultProjectId) : ProjectsScreen.path;

  /// The card of the project [id].
  static Key cardKey(String id) => Key('home.card.$id');

  /// What the signed-in user is in the project [id].
  static Key rolesKey(String id) => Key('home.roles.$id');

  /// The start date of the project [id], and whether it is read-only.
  static Key detailsKey(String id) => Key('home.details.$id');

  /// The status of the project [id].
  static Key statusKey(String id) => Key('home.status.$id');

  /// The unit [id].
  static Key unitKey(String id) => Key('home.unit.$id');

  /// The line of a project [id] with no units.
  static Key noUnitsKey(String id) => Key('home.noUnits.$id');

  /// The way into the people of the project [id].
  static Key usersKey(String id) => Key('home.users.$id');

  /// The way into the categories and items of the project [id].
  static Key categoriesKey(String id) => Key('home.categories.$id');

  /// The way into the VAT rate and payment methods of the project [id].
  static Key paymentMethodsKey(String id) => Key('home.paymentMethods.$id');

  /// The way into the accounts of the project [id].
  static Key accountsKey(String id) => Key('home.accounts.$id');

  /// The way into the partners of the project [id].
  static Key partnersKey(String id) => Key('home.partners.$id');

  /// The way into the suppliers of the project [id].
  static Key suppliersKey(String id) => Key('home.suppliers.$id');

  /// The button that enters a new purchase expense in the running project [id].
  static Key addExpenseKey(String id) => Key('home.addExpense.$id');

  /// The way to the entries of the project [id].
  static Key entriesKey(String id) => Key('home.entries.$id');

  /// How many of the user's entries wait for a decision in the project [id].
  static Key waitingCountKey(String id) => Key('home.waitingCount.$id');

  /// How many of the user's entries were rejected in the project [id].
  static Key rejectedCountKey(String id) => Key('home.rejectedCount.$id');

  /// The way to the revenue of the project [id].
  static Key revenueKey(String id) => Key('home.revenue.$id');

  /// The way to the reports of the project [id].
  static Key reportsKey(String id) => Key('home.reports.$id');

  /// The way to what waits for a decision in the project [id].
  static Key approvalsKey(String id) => Key('home.approvals.$id');

  /// The line saying how many entries of the project [id] wait on this phone.
  static Key waitingKey(String id) => Key('home.waiting.$id');

  /// The way into a new contractor payment in the project [id].
  static Key contractorPaymentKey(String id) => Key('home.contractorPayment.$id');

  /// The way into the contracts of the project [id].
  static Key contractsKey(String id) => Key('home.contracts.$id');

  /// The card of the account [id], which the signed-in user holds.
  static Key custodyKey(String id) => Key('home.custody.$id');

  /// What the account [id] holds, on that card.
  static Key custodyBalanceKey(String id) => Key('home.custodyBalance.$id');

  /// The button that adds a unit to the running project [id].
  static Key addUnitKey(String id) => Key('home.addUnit.$id');

  /// The button that renames the running project [id].
  static Key renameKey(String id) => Key('home.rename.$id');

  /// The menu of the unit [id].
  static Key unitMenuKey(String id) => Key('home.unitMenu.$id');

  /// The way to rename a unit, in its menu.
  static const renameUnitKey = Key('home.renameUnit');

  /// The way to delete a unit, in its menu.
  static const deleteUnitKey = Key('home.deleteUnit');

  /// The button that closes the running project [id].
  static Key closeKey(String id) => Key('home.close.$id');

  /// The way into the blueprints of the project [id].
  static Key blueprintsKey(String id) => Key('home.blueprints.$id');

  /// The way into the liquidation of the project [id].
  static Key liquidateKey(String id) => Key('home.liquidate.$id');

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.projects.loadOnOpen();
    widget.accounts.loadOnOpen();
    widget.entries.loadOnOpen();
    widget.projects.addListener(_leaveIfGone);
    unawaited(widget.sync.refresh(widget.projectId));
  }

  @override
  void dispose() {
    widget.projects.removeListener(_leaveIfGone);
    super.dispose();
  }

  /// Their last role may be taken at any time, and then the project is gone from their list.
  void _leaveIfGone() {
    final projects = widget.projects;
    if (!projects.isLoading && projects.message.isEmpty && !projects.all.any((project) => project.id == widget.projectId && project.isApproved)) {
      context.go(ProjectsScreen.path);
    }
  }

  /// Opens [path] for [project], and reads the figures again on the way back, since what was done there may have changed them (AC-34.1).
  Future<void> _open(String path, Project project) async {
    await context.push(path, extra: project);
    await widget.dashboard.load();
  }

  void _askToClose(Project project) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.projectsCloseQuestion,
        subject: project.name,
        explanation: words.projectsCloseExplain,
        confirmLabel: words.projectsClose,
        onConfirm: () => showRefusalOf(context, widget.projects.close(project)),
      ),
    );
  }

  Future<void> _openUsers(Project project) async {
    await context.push(UsersScreen.pathOf(project.id), extra: project.name);
    await widget.projects.load();
  }

  void _askForUnit(Project project) {
    showDialog<void>(
      context: context,
      builder: (_) => AddUnitDialog(project: project, projects: widget.projects),
    );
  }

  void _askToRename(Project project) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => NameDialog(
        title: words.projectsRename,
        label: words.projectsName,
        saveLabel: words.projectsSave,
        name: project.name,
        onSave: (name) => widget.projects.rename(project, name),
      ),
    );
  }

  void _askToRenameUnit(Project project, Unit unit) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => NameDialog(
        title: words.projectsRenameUnit,
        label: words.projectsUnitName,
        saveLabel: words.projectsSave,
        name: unit.name,
        onSave: (name) => widget.projects.renameUnit(project, unit, name),
      ),
    );
  }

  void _askToDeleteUnit(Project project, Unit unit) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.projectsRemoveUnitQuestion,
        subject: unit.name,
        explanation: words.projectsRemoveUnitExplain,
        confirmLabel: words.projectsRemoveUnit,
        onConfirm: () => showRefusalOf(context, widget.projects.deleteUnit(project, unit)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.projects,
          builder: (context, _) => Text(
            widget.projects.all.where((project) => project.id == widget.projectId).map((project) => project.name).join(),
            key: HomeScreen.titleKey,
          ),
        ),
        actions: [
          NotificationsBell(notifications: widget.notifications),
          IconButton(
            key: HomeScreen.settingsKey,
            icon: const Icon(Icons.tune),
            tooltip: words.settingsTitle,
            onPressed: () => context.push(SettingsScreen.path),
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.projects,
        builder: (context, _) {
          final project = widget.projects.all.where((project) => project.id == widget.projectId && project.mayEnterExpenses).toList();
          return project.isEmpty
              ? const SizedBox.shrink()
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: HomeScreen.addExpenseKey(widget.projectId),
                            icon: const Icon(Icons.add),
                            label: Text(words.expensesNew),
                            onPressed: () => _open(AddExpenseScreen.pathOf(widget.projectId), project.single),
                          ),
                        ),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: HomeScreen.contractorPaymentKey(widget.projectId),
                            icon: const Icon(Icons.handshake_outlined),
                            label: Text(words.contractorPaymentsNew),
                            onPressed: () => _open(ContractorPaymentScreen.pathOf(widget.projectId), project.single),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
        },
      ),
      body: ApiListBody(
        list: widget.projects,
        emptyText: '',
        itemBuilder: (project) => project.id == widget.projectId
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListenableBuilder(
                    listenable: widget.outbox,
                    builder: (context, _) {
                      final waiting = widget.outbox.of(project.id).length;
                      return waiting == 0
                          ? const SizedBox.shrink()
                          : Card.filled(
                              child: ListTile(
                                key: HomeScreen.waitingKey(project.id),
                                leading: const Icon(Icons.cloud_upload_outlined),
                                title: Text('${words.offlineTitle} · $waiting'),
                                onTap: () => context.push(WaitingScreen.pathOf(project.id)),
                              ),
                            );
                    },
                  ),
                  DashboardCard(
                    project: project,
                    dashboard: widget.dashboard,
                    onApprovals: () => _open(ApprovalsScreen.pathOf(project.id), project),
                    onItem: (item) => _open(ItemReportScreen.pathOf(project.id, item.id), project),
                  ),
                  MyCustody(accounts: widget.accounts),
                  MyEntriesSummary(project: project, entries: widget.entries),
                  ProjectCard(
                    project: project,
                    onUsers: () => _openUsers(project),
                    onCategories: () => _open(CategoriesScreen.pathOf(project.id), project),
                    onPaymentMethods: () => _open(PaymentMethodsScreen.pathOf(project.id), project),
                    onAccounts: () => _open(AccountsScreen.pathOf(project.id), project),
                    onPartners: () => _open(PartnersScreen.pathOf(project.id), project),
                    onSuppliers: () => _open(SuppliersScreen.pathOf(project.id), project),
                    onContracts: () => _open(ContractsScreen.pathOf(project.id), project),
                    onApprovals: () => _open(ApprovalsScreen.pathOf(project.id), project),
                    onRevenue: () => _open(RevenueScreen.pathOf(project.id), project),
                    onReports: () => _open(ReportsScreen.pathOf(project.id), project),
                    onLiquidate: () => _open(LiquidationScreen.pathOf(project.id), project),
                    onBlueprints: () => _open(BlueprintsScreen.pathOf(project.id), project),
                    onAddUnit: () => _askForUnit(project),
                    onRename: () => _askToRename(project),
                    onRenameUnit: (unit) => _askToRenameUnit(project, unit),
                    onDeleteUnit: (unit) => _askToDeleteUnit(project, unit),
                    onClose: () => _askToClose(project),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
