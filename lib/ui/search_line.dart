import 'package:flutter/material.dart';

import '../words/words.dart';
import 'filter_line.dart';
import 'part_keys.dart';
import 'search_scope.dart';

/// The one search line of the app (redix-app #104, version 3): shown while its screen's [ScreenSearch] is open, which the title bar's [SearchIcons] does, ready to type,
/// its ✕ closing it and clearing what was typed; under it the filter line while the filter icon has it open. A list body draws it over its rows; a screen that is not
/// one list, such as الإيرادات والمصروفات, over what it shows.
class SearchLine extends StatelessWidget {
  /// The line saying [hint] while empty, with [filters] under it while they are open.
  const SearchLine({super.key, required this.hint, this.filters = const []});

  /// What the empty line says.
  final String hint;

  /// The members of the filter line; none on a screen without filters.
  final List<Widget> filters;

  /// The search line.
  static const searchKey = Key('searchLine');

  /// The ✕ at its end, which closes it and clears what was typed.
  static const closeKey = Key('searchLine.close');

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
              key: searchKey,
              hintText: hint,
              autoFocus: true,
              leading: Icon(Icons.search, key: searchKey.icon),
              trailing: [IconButton(key: closeKey, tooltip: Words.of(context).commonCancel, icon: Icon(Icons.close, key: closeKey.icon), onPressed: search.close)],
              onChanged: search.type,
            ),
          ),
        if (search.filtersOpen && filters.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: FilterLine(members: filters)),
      ],
    );
  }
}
