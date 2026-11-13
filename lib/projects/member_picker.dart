import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import 'members.dart';

/// Chooses someone in a project, or nobody, from a dropdown list of the project's people only (BR-33), each name in full (Muteb, 11 Nov 2026: a list, not radio buttons).
class MemberPicker extends StatelessWidget {
  /// The choice labelled [label] among [members], showing [userId] and answering [onChanged], where [nobody] names an empty choice. The [currentId] called [currentName] stays on offer even if they have left the project; both are empty when there is none.
  const MemberPicker({
    required Key super.key,
    required this.members,
    required this.label,
    required this.nobody,
    required this.userId,
    required this.currentId,
    required this.currentName,
    required this.onChanged,
  });

  /// The people to choose among: the project's own (`GET /projects/{id}/members`).
  final Members members;

  /// What is being chosen.
  final String label;

  /// The word for choosing nobody.
  final String nobody;

  /// Who is chosen; empty for nobody.
  final String userId;

  /// Who held it before this choice; empty when nobody did.
  final String currentId;

  /// That person's name; empty when nobody did.
  final String currentName;

  /// Called with who is chosen; empty for nobody.
  final ValueChanged<String> onChanged;

  /// The choice of the user [id] in the open list; of nobody when that is empty. Its label is the name the closed field shows once it is chosen.
  static Key optionKey(String id) => Key('memberPicker.option.$id');

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: members,
    builder: (context, _) {
      final people = {'': nobody, if (currentId.isNotEmpty) currentId: currentName, for (final member in members.all) member.id: member.displayName};
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: key!.field,
            value: people.containsKey(userId) ? userId : '',
            isExpanded: true,
            isDense: true,
            items: [
              for (final person in people.entries)
                DropdownMenuItem(key: optionKey(person.key), value: person.key, child: Text(person.value, key: optionKey(person.key).title, overflow: TextOverflow.ellipsis)),
            ],
            selectedItemBuilder: (_) => [for (final person in people.entries) Text(person.value, key: optionKey(person.key).label, overflow: TextOverflow.ellipsis)],
            onChanged: (chosen) => onChanged(chosen ?? userId),
          ),
        ),
      );
    },
  );
}
