import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/accounts.dart';
import '../accounts/accounts_screen.dart';
import '../accounts/my_custody.dart';
import '../auth/session.dart';
import '../contracts/contracts_screen.dart';
import '../documents/documents_screen.dart';
import '../partners/movements_screen.dart';
import '../partners/partners_screen.dart';
import '../reports/reports_screen.dart';
import '../approvals/approvals_screen.dart';
import '../entries/add_entry_screen.dart';
import '../entries/home_entries.dart';
import '../entries/project_entries.dart';
import '../notifications/notifications.dart';
import '../notifications/notifications_bell.dart';
import '../offline/outbox.dart';
import '../offline/project_sync.dart';
import '../offline/waiting_screen.dart';
import '../reports/dashboard.dart';
import '../reports/item_report_screen.dart';
import 'dashboard_card.dart';
import '../projects/project.dart';
import '../projects/project_card.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../settings/settings_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/part_keys.dart';
import '../ui/refresh_button.dart';
import '../words/words.dart';

/// The home of the open project (UC-010): the project, with what the user's permissions allow in it (AC-36.2). Each later use case adds to it.
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


  /// The line that says the project could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The button that reads it again.
  static const retryKey = ApiListBody.retryKey;

  /// The route of the home of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId';

  /// Where [session] lands at app start and at sign-in, and nowhere else, so Switch project is never bounced (AC-37.1).
  static String landingOf(Session session) => session.defaultProjectId.isEmpty ? ProjectsScreen.path : pathOf(session.defaultProjectId);

  /// The card of the project [id].
  static Key cardKey(String id) => Key('home.card.$id');

  /// The line that says the project [id] is finished and read-only (redix-api 93).
  static Key finishedKey(String id) => Key('home.finished.$id');

  /// The way into the accounts of the project [id].
  static Key accountsKey(String id) => Key('home.accounts.$id');

  /// The way into the partners of the project [id].
  static Key partnersKey(String id) => Key('home.partners.$id');

  /// The way into the suppliers of the project [id].
  static Key suppliersKey(String id) => Key('home.suppliers.$id');

  /// The button that adds an entry to any table of the running project [id] (redix-app #84).
  static Key addEntryKey(String id) => Key('home.addEntry.$id');

  /// The button beside the entries that searches them, in the project [id].
  static Key searchEntriesKey(String id) => Key('home.searchEntries.$id');

  /// The way to the entries of the project [id].
  static Key entriesKey(String id) => Key('home.entries.$id');

  /// The spinner under the entries' heading while they are first read.
  static const entriesLoadingKey = Key('home.entriesLoading');

  /// The way to the reports of the project [id].
  static Key reportsKey(String id) => Key('home.reports.$id');

  /// The way into the settings of the project [id].
  static Key settingsKey(String id) => Key('home.settings.$id');

  /// The way to what waits for a decision in the project [id].
  static Key approvalsKey(String id) => Key('home.approvals.$id');

  /// The line saying how many entries of the project [id] wait on this phone.
  static Key waitingKey(String id) => Key('home.waiting.$id');

  /// The way into the contracts of the project [id].
  static Key contractsKey(String id) => Key('home.contracts.$id');

  /// The card of the account [id], which the signed-in user holds.
  static Key custodyKey(String id) => Key('home.custody.$id');

  /// What the account [id] holds, on that card.
  static Key custodyBalanceKey(String id) => Key('home.custodyBalance.$id');

  /// The way into the documents of the project [id].
  static Key documentsKey(String id) => Key('home.documents.$id');

  /// The heading over the entries of the project [id].
  static Key entriesHeadingKey(String id) => Key('home.entriesHeading.$id');

  /// The line saying an entry of the project [id] is removed by a swipe (redix-api #102).
  static Key entriesSwipeHintKey(String id) => Key('home.entriesSwipeHint.$id');

  /// The line saying the project [id] has no entries yet.
  static Key entriesEmptyKey(String id) => Key('home.entriesEmpty.$id');

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

  /// They may be taken out of the project at any time, and then the project is gone from their list.
  void _leaveIfGone() {
    final projects = widget.projects;
    if (!projects.isLoading && projects.message.isEmpty && !projects.all.any((project) => project.id == widget.projectId && project.isApproved)) {
      context.go(ProjectsScreen.path);
    }
  }

  /// Opens [path] for [project], and reads what home shows again on the way back, since what was done there may have changed it (AC-34.1).
  Future<void> _open(String path, Project project) async {
    await context.push(path, extra: project);
    await _readAgain();
  }

  /// Reads again what home shows besides the project: its figures, the latest entries and the accounts.
  Future<void> _readAgain() => Future.wait([widget.dashboard.load(), widget.entries.load(), widget.accounts.load()]);

  Future<void> _openSettings(Project project) async {
    await context.push(SettingsScreen.pathOf(project.id), extra: project);
    await Future.wait([widget.projects.load(), _readAgain()]);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.projects,
          builder: (context, _) => Text(
            widget.projects.byId(widget.projectId).name,
            key: HomeScreen.titleKey,
          ),
        ),
        actions: [
          RefreshButton(onRefresh: () => Future.wait([widget.projects.load(), _readAgain()])),
          NotificationsBell(notifications: widget.notifications),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.projects,
        builder: (context, _) {
          final project = widget.projects.byId(widget.projectId);
          return project.isNone
              ? const SizedBox.shrink()
              : BottomButton(buttonKey: HomeScreen.addEntryKey(widget.projectId), label: words.entriesNew, onPressed: project.mayEnterExpenses ? () => _open(AddEntryScreen.pathOf(widget.projectId), project) : null);
        },
      ),
      body: ApiListBody(
        list: widget.projects,
        emptyText: '',
        alsoRefresh: _readAgain,
        keeps: (project) => project.id == widget.projectId,
        itemBuilder: (project) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: widget.outbox,
              builder: (context, _) {
                final waiting = widget.outbox.of(project.id).length;
                return waiting == 0
                    ? const SizedBox.shrink()
                    : Card.filled(
                        key: HomeScreen.waitingKey(project.id).card,
                        child: ListTile(
                          key: HomeScreen.waitingKey(project.id),
                          leading: Icon(Icons.cloud_upload_outlined, key: HomeScreen.waitingKey(project.id).icon),
                          title: Text('${words.offlineTitle} · $waiting', key: HomeScreen.waitingKey(project.id).title),
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
              onPartner: (partner) => _open(MovementsScreen.pathOf(project.id, partner.id, partner.name), project),
            ),
            MyCustody(accounts: widget.accounts),
            HomeEntries(project: project, entries: widget.entries),
            ProjectCard(
              project: project,
              onAccounts: () => _open(AccountsScreen.pathOf(project.id), project),
              onPartners: () => _open(PartnersScreen.pathOf(project.id), project),
              onSuppliers: () => _open(SuppliersScreen.pathOf(project.id), project),
              onContracts: () => _open(ContractsScreen.pathOf(project.id), project),
              onApprovals: () => _open(ApprovalsScreen.pathOf(project.id), project),
              onReports: () => _open(ReportsScreen.pathOf(project.id), project),
              onSettings: () => _openSettings(project),
              onDocuments: () => _open(DocumentsScreen.pathOf(project.id), project),
            ),
          ],
        ),
      ),
    );
  }
}
