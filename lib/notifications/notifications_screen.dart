// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../approvals/approvals_screen.dart';
import '../format/date_format.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'notification_row.dart';
import 'notifications.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../words/word_fill.dart';
import '../format/parts_line.dart';
import '../entries/entry_link_screen.dart';
import '../users/my_permissions_screen.dart';
import '../users/permission_requests_screen.dart';

/// What the person was told (UC-036), newest first. Tapping one opens what it is about.
class NotificationsScreen extends StatefulWidget {
  /// The list of [notifications], whose [projects] it opens.
  const NotificationsScreen({super.key, required this.notifications, required this.projects});

  /// The address of the screen.
  static const path = '/notifications';

  /// The row of the notification [id].
  static Key rowKey(String id) => Key('notifications.row.$id');

  /// What the person was told.
  final Notifications notifications;

  /// The projects they are about.
  final Projects projects;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// The screen a notification of each kind opens in its project; any other kind opens its entry (UC-036, redix-api #112 R6).
final _screens = <String, String Function(String projectId)>{
  'entrySubmitted': ApprovalsScreen.pathOf,
  'permissionRequested': PermissionRequestsScreen.pathOf,
  'permissionRequestApproved': MyPermissionsScreen.pathOf,
  'permissionRequestRejected': MyPermissionsScreen.pathOf,
};

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifications.loadOnOpen();
    widget.projects.loadOnOpen();
  }

  void _open(NotificationRow row) {
    unawaited(widget.notifications.markRead(row));
    final project = widget.projects.byId(row.projectId);
    if (row.isAboutProject || project.isNone) {
      context.go(ProjectsScreen.path);
      return;
    }
    context.push((_screens[row.kind] ?? (projectId) => EntryLinkScreen.pathOf(projectId, row.entryId))(row.projectId), extra: project);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return SearchScope(
      child: Scaffold(
        appBar: AppBar(title: Text(words.notificationsTitle, key: ScreenTitle.titleKey), actions: const [SearchIcons()]),
        body: ApiListBody<NotificationRow>(
          list: widget.notifications,
          emptyText: words.notificationsEmpty,
          search: ListSearch(hint: words.commonSearchIn.fill([words.notificationsTitle]), textOf: (row) => partsLine([words.text('notifications.${row.kind}'), row.projectName])),
          itemBuilder: (row) => ListTile(
            key: NotificationsScreen.rowKey(row.id),
            leading: Icon(row.isRead ? Icons.notifications_none : Icons.notifications_active, key: NotificationsScreen.rowKey(row.id).icon),
            title: Text(words.text('notifications.${row.kind}'), key: NotificationsScreen.rowKey(row.id).title, style: row.isRead ? null : const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${row.projectName} · ${formatDate(row.at)}', key: NotificationsScreen.rowKey(row.id).subtitle),
            onTap: () => _open(row),
          ),
        ),
      ),
    );
  }
}
