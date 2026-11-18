// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/messages.dart';
import '../ui/part_keys.dart';
import '../ui/reason_sheet.dart';
import '../ui/screen_title.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'permission_requests.dart';

/// «طلبات الصلاحيات», from the Project settings card, for whoever manages the project's users (redix-api #112 R3): every request waiting, oldest
/// first, saying who asks, what they ask given and taken, why and when; approving applies it as ticking does (R4), refusing asks why (R8).
class PermissionRequestsScreen extends StatefulWidget {
  /// The requests waiting in [project], read and decided through [requests].
  const PermissionRequestsScreen({super.key, required this.project, required this.requests});

  /// The screen's route.
  static const path = '/projects/:projectId/permission-requests';

  /// The route of the requests of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/permission-requests';

  /// The row of the request [id]; its title names who asks, its subtitle what and why.
  static Key rowKey(String id) => Key('permissionRequests.row.$id');

  /// The approve button of the request [id].
  static Key approveKey(String id) => Key('permissionRequests.approve.$id');

  /// The refuse button of the request [id].
  static Key rejectKey(String id) => Key('permissionRequests.reject.$id');

  /// The project.
  final Project project;

  /// The requests, which decide them.
  final PermissionRequests requests;

  /// What [request] asks and why, a line each, and when.
  static String askedIn(Words words, PermissionRequest request) => [
    if (request.gives.isNotEmpty) words.permissionRequestsGives.fill([request.gives.map((permission) => words.text(permission.wordKey)).join('، ')]),
    if (request.takes.isNotEmpty) words.permissionRequestsTakes.fill([request.takes.map((permission) => words.text(permission.wordKey)).join('، ')]),
    request.reason,
    '${formatDate(request.askedAt)} ${formatTime(request.askedAt)}',
  ].join('\n');

  @override
  State<PermissionRequestsScreen> createState() => _PermissionRequestsScreenState();
}

class _PermissionRequestsScreenState extends State<PermissionRequestsScreen> {
  @override
  void initState() {
    super.initState();
    widget.requests.loadOnOpen();
  }

  Future<void> _approve(BuildContext context, PermissionRequest request) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if ((await showRefusalOf(context, widget.requests.approve(request))).isEmpty) {
      showMessage(messenger, words, 'permissionRequests.approvedDone', values: [request.displayName]);
    }
  }

  void _reject(BuildContext context, PermissionRequest request) {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    ReasonSheet.show(
      context,
      ReasonSheet(
        title: words.permissionRequestsRejectTitle.fill([request.displayName]),
        about: PermissionRequestsScreen.askedIn(words, request),
        reasonLabel: words.permissionRequestsRejectReason,
        sendLabel: words.permissionRequestsReject,
        onSend: (reason) async {
          final refusal = await widget.requests.reject(request, reason);
          if (refusal.isEmpty) {
            showMessage(messenger, words, 'permissionRequests.rejectedDone', values: [request.displayName]);
          }
          return refusal;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.permissionRequestsListTitle, subject: widget.project.name)),
      body: ApiListBody(
        list: widget.requests,
        emptyText: words.permissionRequestsEmpty,
        itemBuilder: (request) => ListTile(
          key: PermissionRequestsScreen.rowKey(request.id),
          title: Text(request.displayName, key: PermissionRequestsScreen.rowKey(request.id).title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(PermissionRequestsScreen.askedIn(words, request), key: PermissionRequestsScreen.rowKey(request.id).subtitle),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(key: PermissionRequestsScreen.approveKey(request.id), onPressed: () => _approve(context, request), child: Text(words.permissionRequestsApprove)),
                  TextButton(key: PermissionRequestsScreen.rejectKey(request.id), onPressed: () => _reject(context, request), child: Text(words.permissionRequestsReject)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
