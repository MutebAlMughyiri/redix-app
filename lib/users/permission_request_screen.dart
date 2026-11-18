// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/permission.dart';
import '../projects/project.dart';
import '../ui/bottom_button.dart';
import '../ui/messages.dart';
import '../ui/one_field_dialog.dart';
import '../ui/screen_title.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'permission_requests.dart';
import 'permission_ticks.dart';

/// «طلب تغيير صلاحياتي», from صلاحياتي (redix-api #112 R1, R5): the person's permissions in [project] as ticks they may change, what they tick asked
/// for and what they untick asked to give up; sending asks the reason (R8), and nothing changes until whoever manages the users approves it.
/// Being in the project, ReadProject, is not theirs to ask; one capital tick takes the other, as ticking does.
class PermissionRequestScreen extends StatefulWidget {
  /// The request of the signed-in person in [project], sent through [mine].
  const PermissionRequestScreen({super.key, required this.project, required this.mine});

  /// The screen's route.
  static const path = '/projects/:projectId/permission-request';

  /// The route of the request in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/permission-request';

  /// What the screen asks.
  static const hintKey = Key('permissionRequest.hint');

  /// The tick of [permission].
  static Key permissionKey(Permission permission) => Key('permissionRequest.${permission.name}');

  /// What the request asks for and gives up, under the reason's field.
  static const askedKey = Key('permissionRequest.asked');

  /// The button that sends it.
  static const sendKey = Key('permissionRequest.send');

  /// The project.
  final Project project;

  /// The person's request, which sends it.
  final MyPermissionRequest mine;

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  late final _held = {for (final permission in Permission.inAProject) if (widget.project.may(permission)) permission};
  late final _wanted = {..._held};

  Iterable<Permission> get _gives => _wanted.difference(_held);

  Iterable<Permission> get _takes => _held.difference(_wanted);

  void _tick(Permission permission, bool ticked) => setState(() {
    if (!ticked) {
      _wanted.remove(permission);
      return;
    }
    _wanted
      ..removeAll(Permission.capitalTicks.contains(permission) ? Permission.capitalTicks : const <Permission>{})
      ..add(permission);
  });

  Future<void> _send() async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var sent = false;
    await showDialog<void>(
      context: context,
      builder: (_) => OneFieldDialog(
        title: words.permissionRequestsTitle,
        label: words.permissionRequestsReason,
        saveLabel: words.permissionRequestsSend,
        below: [Text(_askedIn(words), key: PermissionRequestScreen.askedKey)],
        onSave: (reason) async {
          final refusal = await widget.mine.ask(_gives, _takes, reason);
          sent = refusal.isEmpty;
          return refusal;
        },
      ),
    );
    if (sent && mounted) {
      showMessage(messenger, words, 'permissionRequests.sent');
      context.pop();
    }
  }

  String _askedIn(Words words) => [
    if (_gives.isNotEmpty) words.permissionRequestsGives.fill([_gives.map((permission) => words.text(permission.wordKey)).join('، ')]),
    if (_takes.isNotEmpty) words.permissionRequestsTakes.fill([_takes.map((permission) => words.text(permission.wordKey)).join('، ')]),
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.permissionRequestsTitle, subject: widget.project.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(words.permissionRequestsHint, key: PermissionRequestScreen.hintKey, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          PermissionTicks(
            keyOf: PermissionRequestScreen.permissionKey,
            holds: _wanted.contains,
            onChangedOf: (permission) => permission == Permission.readProject ? null : (ticked) => _tick(permission, ticked),
            partners: const [],
            chosen: (_) => false,
            onChooseOf: (_) => null,
          ),
        ],
      ),
      bottomNavigationBar: BottomButton(
        buttonKey: PermissionRequestScreen.sendKey,
        label: words.permissionRequestsSend,
        icon: Icons.send_outlined,
        onPressed: _gives.isEmpty && _takes.isEmpty ? null : _send,
      ),
    );
  }
}
