import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/search_line.dart';

import 'steps.dart';

/// The steps of searching a list (redix-app #104): the search line, and the filters folded under the arrow at its end.
extension SearchSteps on PatrolIntegrationTester {
  /// Types [typed] in the search line, and waits for the list to answer.
  Future<void> searchFor(String typed) async {
    await reach(this(SearchLine.searchKey));
    await this(SearchLine.searchKey).enterText(typed);
    await pumpAndSettle();
  }

  /// The arrow at the end of the search line: up while the filters show, a filled filter while they are folded and narrow the list, down otherwise.
  IconData get filtersArrow => tester.widget<Icon>(find.byKey(SearchLine.filtersKey.icon)).icon!;

  /// Opens the filters folded under the search line, as its arrow does; nothing when they show already.
  Future<void> openFilters() async {
    await reach(this(SearchLine.filtersKey));
    if (filtersArrow != Icons.arrow_drop_up) {
      await tapOn(SearchLine.filtersKey);
    }
  }

  /// Taps the filter [key] under the search line, opening the line first.
  Future<void> filterBy(Key key) async {
    await openFilters();
    await tapOn(key);
  }

  /// Opens the chip [chip] under the search line and taps [value] in its list, closing the list when it stays open, as a list of many choices does.
  Future<void> chooseIn(Key chip, Key value) async {
    await filterBy(chip);
    await tapOn(value);
    if (tester.widget<Icon>(find.byKey(chip.icon)).icon == Icons.arrow_drop_up) {
      await tapOn(chip);
    }
  }
}
