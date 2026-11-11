import 'package:flutter/widgets.dart';

import 'arabic_spelling.dart';

/// What a list that grows is searched by, and the filters folded under its search line (redix-app #104): the one way a screen asks for search. [ListSearch.none] is a
/// list with no search line.
class ListSearch<T> {
  /// A search line saying [hint], keeping the items whose [textOf] holds what was typed, whichever way an Arabic word is spelled, with [filters] folded under its arrow;
  /// [filtersInUse] while one of them narrows the list, so the folded arrow says so.
  const ListSearch({required this.hint, required this.textOf, this.filters = const [], this.filtersInUse = false});

  /// No search line.
  const ListSearch.none() : hint = '', textOf = _nothing, filters = const [], filtersInUse = false;

  /// What the empty search line says.
  final String hint;

  /// The text an item is searched by.
  final String Function(T item) textOf;

  /// The members of the filter line folded under the search line's arrow; none, and the line has no arrow.
  final List<Widget> filters;

  /// True while a filter narrows the list.
  final bool filtersInUse;

  /// True for a list with no search line.
  bool get isNone => hint.isEmpty;

  /// Whether [item] holds [typed], whichever way an Arabic word is spelled and in whichever digits.
  bool matches(T item, String typed) => searchable(textOf(item)).contains(searchable(typed));

  static String _nothing(Object? item) => '';
}
