// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../ui/busy.dart';
import '../ui/confirm_dialog.dart';
import '../ui/messages.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'project.dart';
import 'project_file_refusals_screen.dart';
import 'projects.dart';

/// Loads a project file into [project] (UC-071, FR-53, redix-api #132): its manager picks the `.json` through [capture] and says yes to what loading it does, in their name,
/// and [projects] sends it. The bar then says what was loaded, from the API's own answer (say only what happened), naming no report for a file that carries none (D9);
/// every row refused opens the refused list, nothing saved (D3, D14); any other refusal is the bar's. Picking nothing changes nothing.
Future<void> loadProjectFile(BuildContext context, Project project, Projects projects, InvoiceCapture capture) async {
  final words = Words.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final file = await whileBusy(context, capture.fromProjectFiles());
  if (file.failure.isNotEmpty) {
    showMessage(messenger, words, file.failure);
  }
  if (file.isNone || !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: words.projectsLoadFileConfirm.fill([file.name, project.name]),
      explanation: words.projectsLoadFileWhat,
      confirmLabel: words.projectsLoadFile,
      onConfirm: () => _send(context, project, projects, file),
    ),
  );
}

Future<void> _send(BuildContext context, Project project, Projects projects, PickedFile file) async {
  final words = Words.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final refusal = await whileBusy(context, projects.loadFile(project, file));
  if (refusal.isEmpty) {
    final loaded = projects.lastLoad;
    showMessage(messenger, words, loaded.report > 0 ? 'projects.loadFileDone' : 'projects.loadFileDoneNoReport', values: ['${loaded.entries}', '${loaded.tables}', '${loaded.report}']);
  } else if (refusal == 'projects.loadFile.rowsRefused' && context.mounted) {
    await context.push(ProjectFileRefusalsScreen.pathOf(project.id), extra: projects.lastRefusals);
  } else {
    showMessage(messenger, words, refusal);
  }
}
