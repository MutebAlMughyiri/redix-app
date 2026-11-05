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
import '../projects/add_unit_dialog.dart';
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
  const HomeScreen({super.key, required this.projectId, required this.projects, required this.accounts});

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

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.projects.loadOnOpen();
    widget.accounts.loadOnOpen();
    widget.projects.addListener(_leaveIfGone);
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
                            onPressed: () => context.push(AddExpenseScreen.pathOf(widget.projectId), extra: project.single),
                          ),
                        ),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: HomeScreen.contractorPaymentKey(widget.projectId),
                            icon: const Icon(Icons.handshake_outlined),
                            label: Text(words.contractorPaymentsNew),
                            onPressed: () => context.push(ContractorPaymentScreen.pathOf(widget.projectId), extra: project.single),
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
                  MyCustody(accounts: widget.accounts),
                  ProjectCard(
                    project: project,
                    onUsers: () => _openUsers(project),
                    onCategories: () => context.push(CategoriesScreen.pathOf(project.id), extra: project),
                    onPaymentMethods: () => context.push(PaymentMethodsScreen.pathOf(project.id), extra: project),
                    onAccounts: () => context.push(AccountsScreen.pathOf(project.id), extra: project),
                    onPartners: () => context.push(PartnersScreen.pathOf(project.id), extra: project),
                    onSuppliers: () => context.push(SuppliersScreen.pathOf(project.id), extra: project),
                    onContracts: () => context.push(ContractsScreen.pathOf(project.id), extra: project),
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
