import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'registered_project.dart';
import 'registered_projects.dart';
import 'registered_projects_screen.dart';

/// Refuses a registered project, saying why, which its manager sees.
class RejectProjectDialog extends StatefulWidget {
  /// The dialog refusing [project] through [projects].
  const RejectProjectDialog({super.key, required this.project, required this.projects});

  /// The project to refuse.
  final RegisteredProject project;

  /// The way to refuse it.
  final RegisteredProjects projects;

  @override
  State<RejectProjectDialog> createState() => _RejectProjectDialogState();
}

class _RejectProjectDialogState extends State<RejectProjectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.registeredReject,
      saveLabel: words.registeredReject,
      onSave: () => widget.projects.reject(widget.project, _reason.text),
      children: [
        Text(widget.project.name, key: RegisteredProjectsScreen.rejectNameKey),
        const SizedBox(height: 16),
        TextField(
          key: RegisteredProjectsScreen.reasonKey,
          controller: _reason,
          maxLines: 3,
          decoration: InputDecoration(labelText: words.registeredReason),
        ),
      ],
    );
  }
}
