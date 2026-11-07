import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../projects/default_project_toggle.dart';
import '../projects/projects.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';

/// The choice of the default project, from Settings (Muteb, 8 Nov 2026): every approved project with a tick, the default one ticked. Ticking another moves the default,
/// unticking it clears it; the default opens at sign-in (AC-37.1).
class DefaultProjectSheet extends StatefulWidget {
  /// The sheet choosing among [projects] the default of [session].
  const DefaultProjectSheet({super.key, required this.session, required this.projects});

  /// The session whose default it is.
  final Session session;

  /// The user's projects.
  final Projects projects;

  /// The sheet's title.
  static const titleKey = Key('defaultProject.title');

  /// What the tick does.
  static const hintKey = Key('defaultProject.hint');

  /// The tick of the project [id].
  static Key optionKey(String id) => Key('defaultProject.option.$id');

  /// Opens the sheet over [context].
  static void show(BuildContext context, Session session, Projects projects) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, useSafeArea: true, builder: (_) => DefaultProjectSheet(session: session, projects: projects));
  }

  @override
  State<DefaultProjectSheet> createState() => _DefaultProjectSheetState();
}

class _DefaultProjectSheetState extends State<DefaultProjectSheet> {
  @override
  void initState() {
    super.initState();
    widget.projects.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.session, widget.projects]),
      builder: (context, _) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(words.settingsDefaultProject, key: DefaultProjectSheet.titleKey, style: theme.textTheme.titleLarge),
          Text(words.settingsDefaultProjectHint, key: DefaultProjectSheet.hintKey, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final project in widget.projects.all.where((project) => project.isApproved))
            CheckboxListTile(
              key: DefaultProjectSheet.optionKey(project.id),
              contentPadding: EdgeInsets.zero,
              title: Text(project.name, key: DefaultProjectSheet.optionKey(project.id).title),
              value: widget.session.defaultProjectId == project.id,
              onChanged: (_) => toggleDefaultProject(context, widget.session, project),
            ),
        ],
      ),
    );
  }
}
