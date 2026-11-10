import 'package:flutter/material.dart';

import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'history_list.dart';

/// The one look of a history (redix-app #101): a chip for every thing it covers and one each, a chip for what I did, the lines newest first, and المزيد while more may follow.
/// The accounts' and the partners' history screens each give it their list, their things and their keys.
class HistoryView extends StatelessWidget {
  /// The view of [history], whose things are [choices] (id and name), the first chip saying [allLabel], each part keyed by its screen.
  const HistoryView({
    super.key,
    required this.history,
    required this.allLabel,
    required this.choices,
    required this.allKey,
    required this.choiceKey,
    required this.mineKey,
    required this.lineKey,
    required this.moreKey,
  });

  /// The history shown.
  final HistoryList history;

  /// What the chip of every thing says.
  final String allLabel;

  /// The things to filter by, each its id and its name.
  final List<(String, String)> choices;

  /// The chip of every thing.
  final Key allKey;

  /// The chip of the thing [id].
  final Key Function(String id) choiceKey;

  /// The chip of what the signed-in user did.
  final Key mineKey;

  /// The line [id].
  final Key Function(int id) lineKey;

  /// The button reading the next page.
  final Key moreKey;

  Widget _filters(Words words) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      ChoiceChip(key: allKey, label: Text(allLabel, key: allKey.label), selected: history.chosenId.isEmpty, onSelected: (_) => history.filter('', history.mine)),
      for (final (id, name) in choices)
        ChoiceChip(key: choiceKey(id), label: Text(name, key: choiceKey(id).label), selected: history.chosenId == id, onSelected: (_) => history.filter(id, history.mine)),
      FilterChip(key: mineKey, label: Text(words.historyMine, key: mineKey.label), selected: history.mine, onSelected: (mine) => history.filter(history.chosenId, mine)),
    ],
  );

  Widget _line(HistoryLine line, Words words) => Card.outlined(
    key: lineKey(line.id),
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(line.icon, key: lineKey(line.id).icon),
      title: Text(line.textIn(words), key: lineKey(line.id).title),
      subtitle: Text(line.whoAndWhenIn(words), key: lineKey(line.id).subtitle),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: _filters(words)),
        Expanded(
          child: ApiListBody(
            list: history,
            emptyText: words.historyEmpty,
            itemBuilder: (line) => _line(line, words),
            listOf: (items) => ListView(
              padding: ApiListBody.padding,
              physics: ApiListBody.physics,
              children: [
                ...items,
                if (history.mayHaveMore) TextButton(key: moreKey, onPressed: () => showRefusalOf(context, history.more()), child: Text(words.historyMore, key: moreKey.label)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
