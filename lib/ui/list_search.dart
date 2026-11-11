import 'package:flutter/widgets.dart';

import 'arabic_spelling.dart';

/// What a list that grows is searched by, and the filters folded under its search line (redix-app #104): the one way a screen asks for search. [ListSearch.none] is a
/// list with no search line.
class ListSearch<T> {
  /// A search line saying [hint], keeping the items whose [textOf] holds what was typed, whichever way an Arabic word is spelled, with [filters] folded under its arrow;
  /// [filtersInUse] while one of them differs from how the screen opens, so the folded arrow says so.
  const ListSearch({required this.hint, required this.textOf, this.filters = const [], this.filtersInUse = false})
    : onTyped = _keptHere,
      searchesOnApi = false,
      autoFocus = false;

  /// A search line saying [hint] whose list the API searches: what is typed goes to [onTyped], which reads the list again, and every item it answers shows, ready to
  /// type at once when [autoFocus]. [filters] and [filtersInUse] as a list searched here.
  const ListSearch.onApi({required this.hint, required this.onTyped, this.filters = const [], this.filtersInUse = false, this.autoFocus = false})
    : textOf = _nothing,
      searchesOnApi = true;

  /// No search line.
  const ListSearch.none() : hint = '', textOf = _nothing, filters = const [], filtersInUse = false, onTyped = _keptHere, searchesOnApi = false, autoFocus = false;

  /// What the empty search line says.
  final String hint;

  /// The text an item is searched by.
  final String Function(T item) textOf;

  /// The members of the filter line folded under the search line's arrow; none, and the line has no arrow.
  final List<Widget> filters;

  /// True while a filter differs from how the screen opens, so the folded arrow says the list is not as it opened.
  final bool filtersInUse;

  /// What is typed, for a list the API searches.
  final ValueChanged<String> onTyped;

  /// True when the API searches the list, so every item it answers shows.
  final bool searchesOnApi;

  /// True to open ready to type.
  final bool autoFocus;

  /// True for a list with no search line.
  bool get isNone => hint.isEmpty;

  /// Whether [item] holds [typed], whichever way an Arabic word is spelled and in whichever digits; every item the API answered, for a list it searches.
  bool matches(T item, String typed) => searchesOnApi || matchesText(textOf(item), typed);

  /// Whether [text] holds [typed], whichever way an Arabic word is spelled and in whichever digits: how the phone matches what was typed, for a list or for a screen that
  /// is not one, such as الإيرادات والمصروفات.
  static bool matchesText(String text, String typed) => searchable(text).contains(searchable(typed));

  /// What shows of a group named [groupName] for [typed], on a screen that groups what it lists: all its [children] when its name holds it, otherwise those whose
  /// [textOf] does. [isShown] is false only when neither does, so a group with nothing in it still shows until a search leaves it out.
  static ({bool isShown, List<C> children}) groupOf<C>(String groupName, List<C> children, String Function(C child) textOf, String typed) {
    if (matchesText(groupName, typed)) {
      return (isShown: true, children: children);
    }
    final kept = [for (final child in children) if (matchesText(textOf(child), typed)) child];
    return (isShown: kept.isNotEmpty, children: kept);
  }

  static String _nothing(Object? item) => '';

  static void _keptHere(String typed) {}
}

/// Tells the rows of a list whether a search narrows it, so what works only on the whole list, such as dragging rows into order, waits until it is cleared.
class ListNarrowed extends InheritedWidget {
  /// [child], the rows of a list that [isNarrowed] while a search holds text.
  const ListNarrowed({super.key, required this.isNarrowed, required super.child});

  /// True while a search narrows the list.
  final bool isNarrowed;

  /// Whether a search narrows the list [context] is in; false outside any list.
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ListNarrowed>()?.isNarrowed ?? false;

  @override
  bool updateShouldNotify(ListNarrowed oldWidget) => oldWidget.isNarrowed != isNarrowed;
}
