// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/permission.dart';
import '../partners/partners.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../ui/api_list_body.dart';
import '../ui/list_search.dart';
import '../ui/screen_title.dart';
import '../ui/search_line.dart';
import '../ui/search_scope.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import '../ui/bottom_button.dart';
import '../ui/messages.dart';
import 'permission_request_screen.dart';
import 'permission_requests.dart';
import 'permission_requests_screen.dart';
import 'permission_ticks.dart';
import 'table_ticks.dart';

/// صلاحياتي, from the home (Muteb, 9 Nov 2026): what the signed-in user may do in a project, each permission as the project manager ticked it, and the partners chosen for them
/// and the tables they see (redix-api #106), read only. Its search keeps the permissions whose name or what it allows holds what was typed (Muteb, 12 Nov 2026). Above them
/// stands the person's latest request to change them, waiting, with a way to withdraw it, or decided; «طلب تغيير» asks for another (redix-api #112).
class MyPermissionsScreen extends StatefulWidget {
  /// The permissions of the signed-in user in [project], read again from [projects] when pulled down, with the [partners] they see and their latest
  /// request, [mine].
  const MyPermissionsScreen({super.key, required this.project, required this.projects, required this.partners, required this.tables, required this.mine});

  /// The screen's route.
  static const path = '/projects/:projectId/my-permissions';

  /// The route of the permissions in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/my-permissions';

  /// What this screen shows, and who changes it.
  static const hintKey = Key('myPermissions.hint');

  /// The tick of [permission].
  static Key permissionKey(Permission permission) => Key('myPermissions.${permission.name}');

  /// Where the person's latest request stands (redix-api #112).
  static const requestKey = Key('myPermissions.request');

  /// The button withdrawing the waiting request.
  static const withdrawKey = Key('myPermissions.withdraw');

  /// The button asking for a change.
  static const askKey = Key('myPermissions.ask');

  /// The project.
  final Project project;

  /// The user's projects, which hold what they may do in each.
  final Projects projects;

  /// The partners the user sees: with chosen capital, those chosen for them.
  final Partners partners;

  /// The project's tables, ticked where the user sees them (redix-api #106 D9).
  final ProjectTables tables;

  /// The person's latest request to change their permissions.
  final MyPermissionRequest mine;

  @override
  State<MyPermissionsScreen> createState() => _MyPermissionsScreenState();
}

class _MyPermissionsScreenState extends State<MyPermissionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.partners.loadOnOpen();
    widget.tables.loadOnOpen();
    widget.mine.loadOnOpen();
  }

  /// Where the latest request stands, and what it asks while it waits.
  Widget _request(Words words, PermissionRequest request) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              words.text('permissionRequests.${request.status.name}').fill([request.rejectionReason]),
              if (request.status == PermissionRequestStatus.waiting) PermissionRequestsScreen.askedIn(words, request),
            ].join('\n'),
            key: MyPermissionsScreen.requestKey,
          ),
          if (request.status == PermissionRequestStatus.waiting)
            TextButton(
              key: MyPermissionsScreen.withdrawKey,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if ((await showRefusalOf(context, widget.mine.withdraw())).isEmpty) {
                  showMessage(messenger, words, 'permissionRequests.withdrawn');
                }
              },
              child: Text(words.permissionRequestsWithdraw),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final projects = widget.projects;
    return SearchScope(
      child: Scaffold(
        appBar: AppBar(title: ScreenTitle(words.permissionsMine, subject: widget.project.name), actions: const [SearchIcons()]),
        bottomNavigationBar: BottomButton(
          buttonKey: MyPermissionsScreen.askKey,
          label: words.permissionRequestsAsk,
          icon: Icons.edit_note,
          onPressed: widget.project.isFinished ? null : () => context.push(PermissionRequestScreen.pathOf(widget.project.id), extra: projects.latest(widget.project)),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchLine(hint: words.commonSearchIn.fill([words.permissionsMine])),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([projects, widget.partners, widget.tables, widget.mine]),
                builder: (context, _) {
                  final latest = projects.latest(widget.project);
                  final typed = ScreenSearch.of(context).typed;
                  return RefreshIndicator(
                    onRefresh: () => Future.wait([projects.load(), widget.tables.load(), widget.mine.load()]),
                    child: ListView(
                      physics: ApiListBody.physics,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Text(words.permissionsMineHint, key: MyPermissionsScreen.hintKey, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        if (!widget.mine.latest.isNone) _request(words, widget.mine.latest),
                        PermissionTicks(
                          keyOf: MyPermissionsScreen.permissionKey,
                          holds: latest.may,
                          onChangedOf: (_) => null,
                          partners: widget.partners.all,
                          chosen: (_) => true,
                          onChooseOf: (_) => null,
                          shows: (permission) => ListSearch.matchesText('${words.text(permission.wordKey)} ${words.text(permission.hintKey)}', typed),
                        ),
                        TableTicks(
                          heading: words.permissionsMineTables,
                          hint: latest.seesEveryTable ? '' : words.reportsPeriodicNotForYou,
                          categories: widget.tables.all,
                          sees: latest.seesTable,
                          onChangedOf: (_) => null,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
