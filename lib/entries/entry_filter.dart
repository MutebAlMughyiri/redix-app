import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../suppliers/arabic_spelling.dart';
import 'entry_row.dart';

/// What the search of a project's entries keeps (redix-app #84): every filter set must hold, and a filter left empty keeps everything.
class EntryFilter {
  /// Where an entry may stand, as the filter offers it: the word key of each, a reversed entry counting as reversed.
  static const statuses = ['entries.pendingApproval', 'entries.approved', 'entries.rejected', 'entries.reversed', 'entries.draft'];

  /// The kinds of entry, as the API names them, each with the word key that names it.
  static const kinds = {'purchase': 'entries.purchases', 'contractorPayment': 'entries.contractorPayments'};

  /// The period that keeps every date.
  static final anyTime = DateTimeRange(start: DateTime(2000), end: DateTime(2100));

  /// What was typed, matched against the item, the supplier or contractor, who entered it, an old bill's number and the amount.
  var text = '';

  /// True to keep only the signed-in user's own.
  var onlyMine = true;

  /// The kinds kept; none chosen keeps both.
  final chosenKinds = <String>{};

  /// Where the kept entries stand; none chosen keeps any.
  final chosenStatuses = <String>{};

  /// The days kept, both ends included.
  var period = anyTime;

  /// True once a period is chosen.
  bool get hasPeriod => period != anyTime;

  /// True while the text, a kind, a status or a period narrows what shows.
  bool get isNarrowed => text.trim().isNotEmpty || chosenKinds.isNotEmpty || chosenStatuses.isNotEmpty || hasPeriod;

  /// Clears the text, the kinds, the statuses and the period; whose entries show stays as chosen.
  void clear() {
    text = '';
    chosenKinds.clear();
    chosenStatuses.clear();
    period = anyTime;
  }

  /// Whether [entry] holds to every filter.
  bool keeps(EntryRow entry) =>
      (!onlyMine || entry.isMine) &&
      (chosenKinds.isEmpty || chosenKinds.contains(entry.kind)) &&
      (chosenStatuses.isEmpty || chosenStatuses.contains(entry.statusWordKey)) &&
      !entry.date.isBefore(period.start) &&
      !entry.date.isAfter(period.end) &&
      entry.searchText.contains(sameSpelling(westernDigits(text.trim())));
}
