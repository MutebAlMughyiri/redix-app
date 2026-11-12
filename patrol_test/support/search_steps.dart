import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/search_line.dart';
import 'package:redix/ui/search_scope.dart';

import 'steps.dart';

/// The steps of searching a list (redix-app #104, version 3): the search line the title bar's search icon shows, and the filters its filter icon shows.
extension SearchSteps on PatrolIntegrationTester {
  /// Types [typed] in the search line, showing it from the title bar's search icon first, and waits for the list to answer.
  Future<void> searchFor(String typed) async {
    await pumpAndSettle();
    if (find.byKey(SearchLine.searchKey).evaluate().isEmpty) {
      await tapOn(SearchIcons.searchKey);
    }
    await reach(this(SearchLine.searchKey));
    await this(SearchLine.searchKey).enterText(typed);
    await Future<void>.delayed(SearchLine.apiPause);
    await pumpAndSettle();
  }

  /// The title bar's filter icon: filled while a filter is in use, outlined otherwise.
  IconData get filtersIcon => tester.widget<Icon>(find.byKey(SearchIcons.filtersKey.icon)).icon!;

  /// Shows the filters from the title bar's filter icon; nothing when they show already.
  Future<void> openFilters() async {
    await reach(this(SearchIcons.filtersKey));
    if (tester.widget<IconButton>(find.byKey(SearchIcons.filtersKey)).isSelected != true) {
      await tapOn(SearchIcons.filtersKey);
    }
  }

  /// Taps the filter [key], showing the filters first.
  Future<void> filterBy(Key key) async {
    await openFilters();
    await tapOn(key);
  }

  /// Opens the chip [chip] among the filters and taps [value] in its list, closing the list when it stays open, as a list of many choices does.
  Future<void> chooseIn(Key chip, Key value) async {
    await filterBy(chip);
    await tapOn(value);
    if (tester.widget<Icon>(find.byKey(chip.icon)).icon == Icons.arrow_drop_up) {
      await tapOn(chip);
    }
  }
}
