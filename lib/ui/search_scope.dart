import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';

/// What one screen's search holds (redix-app #104, version 3): whether its search line shows, whether its filters show, and what is typed. The title bar's
/// [SearchIcons], the search line and the list ask it, so none of them keeps a copy; it lives and dies with its screen, so a search never outlives it (D4).
class ScreenSearch extends ChangeNotifier {
  ScreenSearch._(this._onTyped, this._isOpen);

  final ValueChanged<String> _onTyped;
  bool _isOpen;
  var _filtersOpen = false;
  var _typed = '';

  /// True while the search line shows.
  bool get isOpen => _isOpen;

  /// True while the filter line shows.
  bool get filtersOpen => _filtersOpen;

  /// What is typed; empty once the line is closed.
  String get typed => _typed;

  /// True while what is typed narrows the list.
  bool get isNarrowed => _typed.trim().isNotEmpty;

  /// Shows the search line, ready to type (R1, R3).
  void open() {
    _isOpen = true;
    notifyListeners();
  }

  /// Hides the search line and clears what was typed, so the list shows whole again (R3): the only way the line closes, by its ✕ or the search icon tapped again,
  /// so a closed line never narrows the list.
  void close() {
    _isOpen = false;
    type('');
  }

  /// Shows the filter line, or folds it away (D8); filters set stay applied either way.
  void toggleFilters() {
    _filtersOpen = !_filtersOpen;
    notifyListeners();
  }

  /// Keeps [text] as what is typed, and hands it to the screen.
  void type(String text) {
    if (text == _typed) {
      return;
    }
    _typed = text;
    _onTyped(text);
    notifyListeners();
  }

  /// The search of the screen [context] is in. A search line or a search icon without a [SearchScope] over its screen is a mistake, and says so.
  static ScreenSearch of(BuildContext context) {
    final held = context.dependOnInheritedWidgetOfExactType<_SearchHeld>();
    if (held == null) {
      throw FlutterError('A search line or a search icon needs a SearchScope over its screen (redix-app #104).');
    }
    return held.search;
  }
}

/// Holds the [ScreenSearch] of the screen under it: opening with its line shown when [startsOpen] (R5), and handing what is typed to [onTyped] too, for a screen that
/// searches its own way, on the API or over what is not one list.
class SearchScope extends StatefulWidget {
  /// The search of [child], a screen.
  const SearchScope({super.key, this.startsOpen = false, this.onTyped = _keptHere, required this.child});

  /// True to open with the search line shown and ready to type.
  final bool startsOpen;

  /// Where what is typed goes besides the list under it.
  final ValueChanged<String> onTyped;

  /// The screen.
  final Widget child;

  static void _keptHere(String typed) {}

  @override
  State<SearchScope> createState() => _SearchScopeState();
}

class _SearchScopeState extends State<SearchScope> {
  late final _search = ScreenSearch._((typed) => widget.onTyped(typed), widget.startsOpen);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SearchHeld(search: _search, child: widget.child);
}

class _SearchHeld extends InheritedNotifier<ScreenSearch> {
  const _SearchHeld({required this.search, required super.child}) : super(notifier: search);

  final ScreenSearch search;
}

/// The search icon in a screen's title bar, showing the search line and, tapped again, hiding it (Muteb, 12 Nov 2026); and on a screen with filters the filter icon
/// beside it, filled while a filter is in use, so a narrowed list says so with its lines closed (redix-app #104, D7, D8, R6).
class SearchIcons extends StatelessWidget {
  /// The search icon alone.
  const SearchIcons({super.key}) : hasFilters = false, filtersInUse = false;

  /// The search icon and the filter icon, filled while [filtersInUse].
  const SearchIcons.andFilters({super.key, required this.filtersInUse}) : hasFilters = true;

  /// True on a screen with filters.
  final bool hasFilters;

  /// True while a filter differs from how the screen opens.
  final bool filtersInUse;

  /// The icon that shows the search line.
  static const searchKey = Key('searchIcons.search');

  /// The icon that shows and folds the filter line.
  static const filtersKey = Key('searchIcons.filters');

  @override
  Widget build(BuildContext context) {
    final search = ScreenSearch.of(context);
    final words = Words.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: searchKey,
          tooltip: words.commonSearch,
          isSelected: search.isOpen,
          icon: Icon(Icons.search, key: searchKey.icon),
          onPressed: search.isOpen ? search.close : search.open,
        ),
        if (hasFilters)
          IconButton(
            key: filtersKey,
            tooltip: words.commonFilter,
            isSelected: search.filtersOpen,
            icon: Icon(filtersInUse ? Icons.filter_alt : Icons.filter_alt_outlined, key: filtersKey.icon),
            onPressed: search.toggleFilters,
          ),
      ],
    );
  }
}
