import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/accounts.dart';
import '../accounts/custody_card.dart';
import '../auth/session.dart';
import '../approvals/approvals_screen.dart';
import '../entries/add_entry_screen.dart';
import '../entries/latest_entries.dart';
import '../entries/newest_entries.dart';
import '../notifications/notifications.dart';
import '../notifications/notifications_bell.dart';
import '../offline/outbox.dart';
import '../offline/project_sync.dart';
import '../offline/waiting_screen.dart';
import '../reports/summary.dart';
import 'summary_card.dart';
import '../projects/project.dart';
import '../projects/project_settings_card.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../settings/general_settings_screen.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import '../config/local_config.dart';

/// The home of the open project (UC-010): the project, with what the user's permissions allow in it (AC-36.2). Each later use case adds to it.
class HomeScreen extends StatefulWidget {
  /// The home of the project [projectId], one of [projects], with [accounts], its accounts.
  const HomeScreen({super.key, required this.projectId, required this.projects, required this.accounts, required this.outbox, required this.sync, required this.entries, required this.notifications, required this.summary, required this.localConfig});

  /// Its figures at a glance.
  final Summary summary;

  /// Whether this phone keeps the conclusion and the project's buttons showing.
  final LocalConfig localConfig;

  /// What the user was told.
  final Notifications notifications;

  /// The project's newest entries, as many at a time as this phone shows (redix-app #105).
  final NewestEntries entries;

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

  /// The button beside Settings that hides the conclusion and the project's buttons, and shows them again (redix-app #91).
  static const collapseKey = Key('home.collapse');

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

  /// Show more, under the entries of the project [id]: as many again as show at a time (redix-app #105).
  static Key moreEntriesKey(String id) => Key('home.moreEntries.$id');

  /// The arrow under the Project settings of the project [id], opening them on every button and closing them on the four used most.
  static Key moreSettingsKey(String id) => Key('home.moreSettings.$id');

  /// The spinner under the entries' heading while they are first read.
  static const entriesLoadingKey = Key('home.entriesLoading');

  /// The way to the reports of the project [id].
  static Key reportsKey(String id) => Key('home.reports.$id');

  /// The way into the item reports of the project [id] (Muteb, 9 Nov 2026).
  static Key itemReportsKey(String id) => Key('home.itemReports.$id');

  /// The way into the VAT refund of the project [id] (Muteb, 9 Nov 2026).
  static Key vatKey(String id) => Key('home.vat.$id');

  /// What the signed-in user is called in the project, under its name (Muteb, 9 Nov 2026).
  static const roleNameKey = Key('home.roleName');

  /// The way into the settings of the project [id]: a gear in the top bar (Muteb, 8 and 9 Nov 2026).
  static Key generalSettingsKey(String id) => Key('home.generalSettings.$id');

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

  /// The way into More info of the project [id], moved from Settings (Muteb, 9 Nov 2026).
  static Key projectInfoKey(String id) => Key('home.projectInfo.$id');

  /// The way into what the signed-in user may do in the project [id], read only (Muteb, 9 Nov 2026).
  static Key myPermissionsKey(String id) => Key('home.myPermissions.$id');

  /// The way into the users of the project [id], moved from Settings (Muteb, 9 Nov 2026).
  static Key usersKey(String id) => Key('home.users.$id');

  /// The way into the categories and items of the project [id], moved from Settings (Muteb, 9 Nov 2026).
  static Key categoriesKey(String id) => Key('home.categories.$id');

  /// The way into the payment methods of the project [id], moved from Settings (Muteb, 9 Nov 2026).
  static Key paymentMethodsKey(String id) => Key('home.paymentMethods.$id');

  /// Importing the settings of the project [id], grayed until it is built (Muteb, 9 Nov 2026).
  static Key importSettingsKey(String id) => Key('home.importSettings.$id');

  /// The heading over the entries of the project [id].
  static Key entriesHeadingKey(String id) => Key('home.entriesHeading.$id');

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
    widget.entries.openFirstPage();
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

  /// Opens the screen at [path] of [project], and on coming back reads again the project, which may have changed there, and what the home shows besides it.
  Future<void> _open(String path, Project project) async {
    await context.push(path, extra: project);
    await Future.wait([widget.projects.load(), _readAgain()]);
  }

  void _toggleDetails() {
    widget.localConfig.toggleHomeDetails();
    setState(() {});
  }

  /// Reads again what home shows besides the project: its figures, the latest entries and the accounts.
  Future<void> _readAgain() => Future.wait([widget.summary.load(), widget.entries.load(), widget.accounts.load()]);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final showsDetails = widget.localConfig.showsHomeDetails;
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.projects,
          builder: (context, _) {
            final project = widget.projects.byId(widget.projectId);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, key: HomeScreen.titleKey),
                if (project.roleName.isNotEmpty) Text(project.roleName, key: HomeScreen.roleNameKey, style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            key: HomeScreen.collapseKey,
            tooltip: showsDetails ? words.homeHideDetails : words.homeShowDetails,
            icon: Icon(showsDetails ? Icons.unfold_less : Icons.unfold_more, key: HomeScreen.collapseKey.icon),
            onPressed: _toggleDetails,
          ),
          ListenableBuilder(
            listenable: widget.projects,
            builder: (context, _) {
              final project = widget.projects.byId(widget.projectId);
              return IconButton(
                key: HomeScreen.generalSettingsKey(widget.projectId),
                tooltip: words.generalSettingsTitle,
                icon: Icon(Icons.settings_outlined, key: HomeScreen.generalSettingsKey(widget.projectId).icon),
                onPressed: project.isNone ? null : () => _open(GeneralSettingsScreen.path, project),
              );
            },
          ),
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
            if (showsDetails) SummaryCard(
              project: project,
              summary: widget.summary,
              onApprovals: () => _open(ApprovalsScreen.pathOf(project.id), project),
            ),
            CustodyCard(accounts: widget.accounts),
            LatestEntries(project: project, entries: widget.entries, onOpen: (path) => _open(path, project), onRemoved: widget.summary.load),
            if (showsDetails) ProjectSettingsCard(project: project, onOpen: (path) => _open(path, project)),
          ],
        ),
      ),
    );
  }
}
