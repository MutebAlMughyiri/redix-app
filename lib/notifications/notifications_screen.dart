import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../approvals/approvals_screen.dart';
import '../entries/entries_screen.dart';
import '../format/date_format.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'notification_row.dart';
import 'notifications.dart';

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
    context.push(row.asksForDecision ? ApprovalsScreen.pathOf(row.projectId) : EntriesScreen.pathOfEntry(row.projectId, row.entryId), extra: project);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.notificationsTitle, key: ScreenTitle.titleKey)),
      body: ApiListBody(
        list: widget.notifications,
        emptyText: words.notificationsEmpty,
        itemBuilder: (row) => ListTile(
          key: NotificationsScreen.rowKey(row.id),
          leading: Icon(row.isRead ? Icons.notifications_none : Icons.notifications_active, key: NotificationsScreen.rowKey(row.id).icon),
          title: Text(words.text('notifications.${row.kind}'), key: NotificationsScreen.rowKey(row.id).title, style: row.isRead ? null : const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${row.projectName} · ${formatDate(row.at)}', key: NotificationsScreen.rowKey(row.id).subtitle),
          onTap: () => _open(row),
        ),
      ),
    );
  }
}
