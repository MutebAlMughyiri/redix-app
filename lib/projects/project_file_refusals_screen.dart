// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import '../ui/refusal_text.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'project_file_refusal.dart';

/// What a project file's load refused (UC-071, AC-53.5, D14): nothing was saved, and every row or part refused is listed at once, by the file's item and table and the row's
/// place as its sheet numbers it, each with its owner's own word for why, so the file is fixed and loaded again.
class ProjectFileRefusalsScreen extends StatelessWidget {
  /// The [refusals] of loading a file into the project [projectName].
  const ProjectFileRefusalsScreen({super.key, required this.projectName, required this.refusals});

  /// The screen's route.
  static const path = '/projects/:projectId/project-file/refused';

  /// The route of what loading a file into the project [projectId] refused.
  static String pathOf(String projectId) => '/projects/$projectId/project-file/refused';

  /// The line saying nothing was saved, over the list.
  static const headingKey = Key('projectFileRefusals.heading');

  /// The refusal at [index] in the list, from 0: its place is its title, its reason its subtitle.
  static Key refusalKey(int index) => Key('projectFileRefusals.refusal.$index');

  /// The project the file was loaded into.
  final String projectName;

  /// Every refusal, in the order the API found them.
  final List<ProjectFileRefusal> refusals;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.projectsLoadFile, subject: projectName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          refusalText(context, words.projectsLoadFileRowsRefused, headingKey),
          for (final (index, refusal) in refusals.indexed)
            ListTile(
              key: refusalKey(index),
              contentPadding: EdgeInsets.zero,
              title: Text(refusal.place, key: refusalKey(index).title),
              subtitle: Text(refusal.reasonIn(words), key: refusalKey(index).subtitle),
            ),
        ],
      ),
    );
  }
}
