import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../ui/messages.dart';
import '../words/words.dart';
import 'project.dart';

/// Makes [project] the default project of [session], or clears it when it already is, the one way the star and Settings both change it. Once a project becomes the
/// default, a message says so (Muteb, 8 Nov 2026); a refusal says why.
Future<void> toggleDefaultProject(BuildContext context, Session session, Project project) async {
  final words = Words.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final isDefault = session.defaultProjectId == project.id;
  final refusal = await (isDefault ? session.removeDefaultProject() : session.setDefaultProject(project.id));
  if (refusal.isNotEmpty) {
    showMessage(messenger, words, refusal);
  } else if (!isDefault) {
    showMessage(messenger, words, 'projects.defaultSet', values: [project.name]);
  }
}
