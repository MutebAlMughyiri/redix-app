// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../format/date_format.dart';
import '../reports/report_files.dart';
import '../ui/busy.dart';
import '../ui/confirm_dialog.dart';
import '../ui/messages.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'project.dart';
import 'projects.dart';

/// What a retrieve's preview counts, now and after, each as the API names it (UC-073 D8).
enum ArchivePart {
  /// القيود.
  entries,

  /// العقود.
  contracts,

  /// الحسابات.
  accounts,

  /// الموردون.
  suppliers,

  /// الشركاء.
  partners,

  /// البنود.
  items,

  /// الملفات: the attachments and documents' files.
  attachments;

  /// The word that names it.
  String get wordKey => 'projects.retrieve.part.$name';
}

/// What the API answered a retrieve or its preview (UC-073 AC-73.2): when the archive was taken and by whom, how many of each part the project holds now and
/// after; and, when it was refused as another project's archive, that project's name.
class ArchiveRetrieval {
  /// The answer [json].
  ArchiveRetrieval.fromJson(Map<String, dynamic> json)
    : archivedAt = json['archivedAt'] as String? ?? '',
      archivedBy = json['archivedBy'] as String? ?? '',
      now = _countsOf(json['now']),
      after = _countsOf(json['after']),
      project = json['project'] as String? ?? '';

  /// When the archive was taken, as the API wrote it.
  final String archivedAt;

  /// Who took it.
  final String archivedBy;

  /// How many of each part the project holds now; 0 each in a retrieve's answer, which says only after.
  final Map<ArchivePart, int> now;

  /// How many of each part the project holds after the retrieve.
  final Map<ArchivePart, int> after;

  /// The project an archive of another project is of; empty for any other answer.
  final String project;

  /// When the archive was taken, as a person reads a moment.
  String get when => '${formatDate(momentOf(archivedAt))} ${formatTime(momentOf(archivedAt))}';

  static Map<ArchivePart, int> _countsOf(Object? sent) {
    final counts = sent as Map<String, dynamic>? ?? const {};
    return {for (final part in ArchivePart.values) part: counts[part.name] as int? ?? 0};
  }
}

/// Takes [project]'s archive through [files] and hands it to the phone, saved or shared as a report's file is (UC-073 AC-73.1), named «{project} - أرشيف {date time}»
/// by the server's clock.
Future<void> archiveProject(BuildContext context, Project project, ReportFiles files) {
  final at = files.clock.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final name = Words.of(context).projectsArchiveFileName.fill([project.name, '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}.${two(at.minute)}']);
  return handReportFile(context, files, '/projects/${project.id}/archive', name, ReportFileKind.archive);
}

/// Retrieves an archive over [project] (UC-073): its holder picks the `.json` through [capture], and [projects] asks the API what retrieving it would do, which the
/// question shows with what stays (AC-73.2, D8); once they say yes it is sent again and retrieved, and the bar says when the archive was taken and how many entries
/// the project holds now, from the API's own answer. A refusal is the bar's, naming another project's archive; picking nothing changes nothing.
Future<void> retrieveProject(BuildContext context, Project project, Projects projects, InvoiceCapture capture) async {
  final words = Words.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final file = await whileBusy(context, capture.fromArchives());
  if (file.failure.isNotEmpty) {
    showMessage(messenger, words, file.failure);
  }
  if (file.isNone || !context.mounted) {
    return;
  }
  final refusal = await whileBusy(context, projects.previewRetrieve(project, file));
  if (refusal.isNotEmpty) {
    showMessage(messenger, words, refusal, values: [projects.lastRetrieval.project]);
  }
  if (refusal.isNotEmpty || !context.mounted) {
    return;
  }
  final preview = projects.lastRetrieval;
  await showDialog<void>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: words.projectsRetrieveConfirm.fill([project.name, preview.when]),
      explanation: [
        words.projectsRetrieveTakenBy.fill([preview.archivedBy]),
        for (final part in ArchivePart.values) '${words.text(part.wordKey)}: ${words.projectsRetrieveNow} ${preview.now[part]} · ${words.projectsRetrieveAfter} ${preview.after[part]}',
        words.projectsRetrieveWhat,
      ].join('\n'),
      confirmLabel: words.projectsRetrieve,
      onConfirm: () => _retrieve(context, project, projects, file),
    ),
  );
}

Future<void> _retrieve(BuildContext context, Project project, Projects projects, PickedFile file) async {
  final words = Words.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final refusal = await whileBusy(context, projects.retrieve(project, file));
  final retrieved = projects.lastRetrieval;
  if (refusal.isEmpty) {
    showMessage(messenger, words, 'projects.retrieveDone', values: [retrieved.when, '${retrieved.after[ArchivePart.entries]}']);
  } else {
    showMessage(messenger, words, refusal, values: [retrieved.project]);
  }
}
