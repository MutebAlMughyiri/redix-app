import 'package:flutter/material.dart';

import '../words/words.dart';
import 'filter_line.dart';
import 'part_keys.dart';
import 'search_scope.dart';

/// The one search line of the app (redix-app #104, version 3): shown while its screen's [ScreenSearch] is open, which the title bar's [SearchIcons] does, ready to type,
/// its ✕ closing it and clearing what was typed; under it the filter line while the filter icon has it open. A list body draws it over its rows; a screen that is not
/// one list, such as الإيرادات والمصروفات, over what it shows.
class SearchLine extends StatefulWidget {
  /// The line saying [hint] while empty, with [filters] under it while they are open, handing what is typed on once typing pauses when it [waits].
  const SearchLine({super.key, required this.hint, this.filters = const [], this.waits = false});

  /// What the empty line says.
  final String hint;

  /// The members of the filter line; none on a screen without filters.
  final List<Widget> filters;

  /// True for a list the API searches: what is typed is handed to the screen's search once typing pauses for [apiPause], so a word typed asks the API once, not once per
  /// letter (findings row 210). A list searched on the phone answers each letter.
  final bool waits;

  /// How long typing pauses before a line that [waits] hands on what was typed.
  static const apiPause = Duration(milliseconds: 300);

  /// The search line.
  static const searchKey = Key('searchLine');

  /// The ✕ at its end, which closes it and clears what was typed.
  static const closeKey = Key('searchLine.close');

  @override
  State<SearchLine> createState() => _SearchLineState();
}

class _SearchLineState extends State<SearchLine> {
  /// What was typed or closed so far, so only the last of them is handed on once typing pauses.
  var _changes = 0;

  void _typed(ScreenSearch search, String text) {
    final change = ++_changes;
    if (!widget.waits) {
      search.type(text);
      return;
    }
    Future<void>.delayed(SearchLine.apiPause, () {
      if (mounted && change == _changes) {
        search.type(text);
      }
    });
  }

  void _close(ScreenSearch search) {
    _changes++;
    search.close();
  }

  @override
  Widget build(BuildContext context) {
    final search = ScreenSearch.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (search.isOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              key: SearchLine.searchKey,
              hintText: widget.hint,
              autoFocus: true,
              leading: Icon(Icons.search, key: SearchLine.searchKey.icon),
              trailing: [
                IconButton(key: SearchLine.closeKey, tooltip: Words.of(context).commonCancel, icon: Icon(Icons.close, key: SearchLine.closeKey.icon), onPressed: () => _close(search)),
              ],
              onChanged: (text) => _typed(search, text),
            ),
          ),
        if (search.filtersOpen && widget.filters.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: FilterLine(members: widget.filters)),
      ],
    );
  }
}
