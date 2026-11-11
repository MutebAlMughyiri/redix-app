import 'package:flutter/material.dart';

import 'filter_line.dart';
import 'list_search.dart';
import 'part_keys.dart';

/// The one search line of the app (redix-app #104): what was typed, and the filters folded under the arrow at its end, closed as the screen opens. A list body draws it
/// over its rows; a screen that is not one list, such as الإيرادات والمصروفات, over what it shows.
class SearchLine extends StatefulWidget {
  /// The line of [search], calling [onTyped] with what is typed each time it changes.
  const SearchLine({super.key, required this.search, required this.onTyped});

  /// What the line says, and the filters under it.
  final ListSearch<Object?> search;

  /// Called with what is typed.
  final ValueChanged<String> onTyped;

  /// The search line.
  static const searchKey = Key('searchLine');

  /// The arrow at its end, opening and folding its filters.
  static const filtersKey = Key('searchLine.filters');

  @override
  State<SearchLine> createState() => _SearchLineState();
}

class _SearchLineState extends State<SearchLine> {
  var _filtersOpen = false;

  /// The arrow: up while the filters show, a filled filter while they are folded and narrow the list, down otherwise.
  IconData get _filtersIcon => _filtersOpen ? Icons.arrow_drop_up : (widget.search.filtersInUse ? Icons.filter_alt : Icons.arrow_drop_down);

  @override
  Widget build(BuildContext context) {
    final search = widget.search;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(
            key: SearchLine.searchKey,
            hintText: search.hint,
            autoFocus: search.autoFocus,
            leading: Icon(Icons.search, key: SearchLine.searchKey.icon),
            trailing: [
              if (search.filters.isNotEmpty)
                IconButton(key: SearchLine.filtersKey, icon: Icon(_filtersIcon, key: SearchLine.filtersKey.icon), onPressed: () => setState(() => _filtersOpen = !_filtersOpen)),
            ],
            onChanged: widget.onTyped,
          ),
        ),
        if (_filtersOpen) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: FilterLine(members: search.filters)),
      ],
    );
  }
}
