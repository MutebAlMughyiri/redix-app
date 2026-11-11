import 'package:flutter/material.dart';

import 'entry_kind.dart';

/// What the search of a project's entries asks the API to keep (redix-app #84, #104): every filter set must hold, and a filter left empty keeps everything.
class EntryFilter {
  /// Where an entry may stand, as the filter offers it: the word key of each, a reversed entry counting as reversed.
  static const statuses = ['entries.pendingApproval', 'entries.approved', 'entries.rejected', 'entries.reversed', 'entries.draft'];

  /// The period that keeps every date.
  static final anyTime = DateTimeRange(start: DateTime(2000), end: DateTime(2100));

  /// What was typed, which the API matches against the item, the supplier or contractor, who entered it, an old bill's number and the amount.
  var text = '';

  /// True to keep only the signed-in user's own.
  var onlyMine = true;

  /// The kinds kept; none chosen keeps every kind.
  final chosenKinds = <EntryKind>{};

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
}
