import 'package:flutter/material.dart';

import '../ui/api_list_body.dart';
import '../ui/filter_line.dart';
import '../ui/list_search.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'history_list.dart';

/// The one look of a history (redix-app #101, #104): the shared search line, which the API searches, with its filters folded under the arrow, a chip choosing every thing it
/// covers or one and a chip for what I did; the lines newest first, and المزيد while more may follow. The accounts' and the partners' history screens each give it their
/// list, their things and their keys.
class HistoryView extends StatelessWidget {
  /// The view of [history], called [title], whose things are [choices] (id and name), each called a [choiceLabel], each part keyed by its screen.
  const HistoryView({
    super.key,
    required this.history,
    required this.title,
    required this.choiceLabel,
    required this.choices,
    required this.choiceChipKey,
    required this.allKey,
    required this.choiceKey,
    required this.mineKey,
    required this.lineKey,
    required this.moreKey,
  });

  /// The history shown.
  final HistoryList history;

  /// What the history is called, which the empty search line names.
  final String title;

  /// What one of its things is called, which the chip choosing them says before the one chosen.
  final String choiceLabel;

  /// The things to filter by, each its id and its name.
  final List<(String, String)> choices;

  /// The chip opening the list of things.
  final Key choiceChipKey;

  /// Every thing, in that list.
  final Key allKey;

  /// The thing [id], in that list.
  final Key Function(String id) choiceKey;

  /// The chip of what the signed-in user did.
  final Key mineKey;

  /// The line [id].
  final Key Function(int id) lineKey;

  /// The button reading the next page.
  final Key moreKey;

  List<Widget> _filters(Words words) {
    final values = [('', words.historyAll), ...choices];
    return [
      FilterLine.choice<(String, String)>(
        key: choiceChipKey,
        label: choiceLabel,
        values: values,
        chosen: values.firstWhere((value) => value.$1 == history.chosenId, orElse: () => values.first),
        labelOf: (value) => value.$2,
        keyOf: (value) => value.$1.isEmpty ? allKey : choiceKey(value.$1),
        onChanged: (value) => history.filter(value.$1, history.mine),
      ),
      FilterLine.toggle(key: mineKey, label: words.historyMine, isOn: history.mine, onChanged: (mine) => history.filter(history.chosenId, mine)),
    ];
  }

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
    return ApiListBody<HistoryLine>(
      list: history,
      emptyText: words.historyEmpty,
      search: ListSearch.onApi(
        hint: words.commonSearchIn.fill([title]),
        filters: _filters(words),
      ),
      itemBuilder: (line) => _line(line, words),
      listOf: (items) => ListView(
        padding: ApiListBody.padding,
        physics: ApiListBody.physics,
        children: [
          ...items,
          if (history.mayHaveMore) TextButton(key: moreKey, onPressed: () => showRefusalOf(context, history.more()), child: Text(words.historyMore, key: moreKey.label)),
        ],
      ),
    );
  }
}
