import 'package:flutter/material.dart';

import 'members.dart';

/// Chooses someone in a project, or nobody, as a list of choices with every name in full.
class MemberPicker extends StatelessWidget {
  /// The choice labelled [label] among [members], showing [userId] and answering [onChanged], where [nobody] names an empty choice. The [currentId] called [currentName] stays on offer even if they have left the project; both are empty when there is none.
  const MemberPicker({
    super.key,
    required this.members,
    required this.label,
    required this.nobody,
    required this.userId,
    required this.currentId,
    required this.currentName,
    required this.onChanged,
  });

  /// The people to choose among.
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

  /// The choice of the user [id]; of nobody when that is empty.
  static Key optionKey(String id) => Key('memberPicker.option.$id');

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: members,
    builder: (context, _) {
      final people = {'': nobody, if (currentId.isNotEmpty) currentId: currentName, for (final member in members.all) member.id: member.displayName};
      return RadioGroup<String>(
        groupValue: userId,
        onChanged: (chosen) => onChanged(chosen ?? userId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            for (final person in people.entries)
              RadioListTile<String>(key: optionKey(person.key), contentPadding: EdgeInsets.zero, value: person.key, title: Text(person.value)),
          ],
        ),
      );
    },
  );
}
