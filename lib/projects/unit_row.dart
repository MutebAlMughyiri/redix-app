// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'project.dart';
import 'project_info_screen.dart';
import '../ui/row_menu.dart';

/// One unit on More info: its name and, for whoever manages the open project, a menu to rename it and a swipe that removes it (redix-api #102).
class UnitRow extends StatelessWidget {
  /// The row of [unit], offering [onRename] and [onRemove] while [mayChange].
  const UnitRow({super.key, required this.unit, required this.mayChange, required this.onRename, required this.onRemove});

  /// The unit this row shows.
  final Unit unit;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  /// Asks for its new name.
  final VoidCallback onRename;

  /// Removes it; answers an empty string once removed, otherwise the word key of the refusal, such as a unit in use.
  final Future<String> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return SwipeToRemove(
      rowKey: ProjectInfoScreen.unitRowKey(unit.id),
      mayRemove: mayChange,
      onRemove: onRemove,
      child: ListTile(
      key: ProjectInfoScreen.unitRowKey(unit.id),
      dense: true,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
      title: Text(unit.name, key: ProjectInfoScreen.unitKey(unit.id)),
      trailing: mayChange
          ? rowMenu(ProjectInfoScreen.unitMenuKey(unit.id), [
                rowMenuItem(ProjectInfoScreen.renameUnitKey, words.projectsRenameUnit, onRename),
              ])
          : null,
      ),
    );
  }
}
