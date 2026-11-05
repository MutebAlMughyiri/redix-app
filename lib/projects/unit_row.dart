import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../words/words.dart';
import 'project.dart';

/// One unit on the project's home: its name and, for whoever manages the open project, a menu to rename or delete it.
class UnitRow extends StatelessWidget {
  /// The row of [unit], offering [onRename] and [onDelete] while [mayChange].
  const UnitRow({super.key, required this.unit, required this.mayChange, required this.onRename, required this.onDelete});

  /// The unit this row shows.
  final Unit unit;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  /// Asks for its new name.
  final VoidCallback onRename;

  /// Asks whether to delete it.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListTile(
      dense: true,
      title: Text(unit.name, key: HomeScreen.unitKey(unit.id)),
      trailing: mayChange
          ? PopupMenuButton<VoidCallback>(
              key: HomeScreen.unitMenuKey(unit.id),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                PopupMenuItem(key: HomeScreen.renameUnitKey, value: onRename, child: Text(words.projectsRenameUnit)),
                PopupMenuItem(key: HomeScreen.deleteUnitKey, value: onDelete, child: Text(words.projectsRemoveUnit)),
              ],
            )
          : null,
    );
  }
}
