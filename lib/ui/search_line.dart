import 'package:flutter/material.dart';

import 'filter_line.dart';
import 'part_keys.dart';

/// The one search line of the app (redix-app #104): what was typed, and the filters folded under the arrow at its end, closed as the screen opens. A list body draws it
/// over its rows; a screen that is not one list, such as الإيرادات والمصروفات, over what it shows.
class SearchLine extends StatefulWidget {
  /// The line saying [hint] while empty, calling [onTyped] with what is typed each time it changes, ready to type at once when [autoFocus], with [filters] folded
  /// under its arrow.
  const SearchLine({super.key, required this.hint, required this.onTyped, this.filters = const [], this.filtersInUse = false, this.autoFocus = false});

  /// What the empty line says.
  final String hint;

  /// The members of the filter line folded under the arrow; none, and the line has no arrow.
  final List<Widget> filters;

  /// True while a filter differs from how the screen opens, so the folded arrow says the list is not as it opened.
  final bool filtersInUse;

  /// True to open ready to type.
  final bool autoFocus;

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

  /// The arrow: up while the filters show, a filled filter while they are folded and in use, down otherwise.
  IconData get _filtersIcon => _filtersOpen ? Icons.arrow_drop_up : (widget.filtersInUse ? Icons.filter_alt : Icons.arrow_drop_down);

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(
            key: SearchLine.searchKey,
            hintText: widget.hint,
            autoFocus: widget.autoFocus,
            leading: Icon(Icons.search, key: SearchLine.searchKey.icon),
            trailing: [
              if (widget.filters.isNotEmpty)
                IconButton(key: SearchLine.filtersKey, icon: Icon(_filtersIcon, key: SearchLine.filtersKey.icon), onPressed: () => setState(() => _filtersOpen = !_filtersOpen)),
            ],
            onChanged: widget.onTyped,
          ),
        ),
        if (_filtersOpen) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: FilterLine(members: widget.filters)),
      ],
    );
}
