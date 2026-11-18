// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

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
import 'permission_ticks.dart';

/// صلاحياتي, from the home (Muteb, 9 Nov 2026): what the signed-in user may do in a project, each permission as the project manager ticked it, and the partners chosen for them
/// (redix-api #106), read only. Its search keeps the permissions whose name or what it allows holds what was typed (Muteb, 12 Nov 2026).
class MyPermissionsScreen extends StatefulWidget {
  /// The permissions of the signed-in user in [project], read again from [projects] when pulled down, with the [partners] they see.
  const MyPermissionsScreen({super.key, required this.project, required this.projects, required this.partners});

  /// The screen's route.
  static const path = '/projects/:projectId/my-permissions';

  /// The route of the permissions in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/my-permissions';

  /// What this screen shows, and who changes it.
  static const hintKey = Key('myPermissions.hint');

  /// The tick of [permission].
  static Key permissionKey(Permission permission) => Key('myPermissions.${permission.name}');

  /// The project.
  final Project project;

  /// The user's projects, which hold what they may do in each.
  final Projects projects;

  /// The partners the user sees: with chosen capital, those chosen for them.
  final Partners partners;

  @override
  State<MyPermissionsScreen> createState() => _MyPermissionsScreenState();
}

class _MyPermissionsScreenState extends State<MyPermissionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.partners.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final projects = widget.projects;
    return SearchScope(
      child: Scaffold(
        appBar: AppBar(title: ScreenTitle(words.permissionsMine, subject: widget.project.name), actions: const [SearchIcons()]),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchLine(hint: words.commonSearchIn.fill([words.permissionsMine])),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([projects, widget.partners]),
                builder: (context, _) {
                  final latest = projects.latest(widget.project);
                  final typed = ScreenSearch.of(context).typed;
                  return RefreshIndicator(
                    onRefresh: projects.load,
                    child: ListView(
                      physics: ApiListBody.physics,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Text(words.permissionsMineHint, key: MyPermissionsScreen.hintKey, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        PermissionTicks(
                          keyOf: MyPermissionsScreen.permissionKey,
                          holds: latest.may,
                          onChangedOf: (_) => null,
                          partners: widget.partners.all,
                          chosen: (_) => true,
                          onChooseOf: (_) => null,
                          shows: (permission) => ListSearch.matchesText('${words.text(permission.wordKey)} ${words.text(permission.hintKey)}', typed),
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
