import 'package:flutter/material.dart';

/// Where an entry stands, named as the API names it (findings row 163).
enum EntryStatus {
  /// Saved by who entered it, and seen by nobody's inbox.
  draft,

  /// Waiting for a decision.
  pendingApproval,

  /// Approved: it counts in every total, and never changes again.
  approved,

  /// Rejected, with a reason, to be fixed and sent again.
  rejected;

  /// The key of the word that says it.
  String get wordKey => 'entries.$name';

  /// Whether its color marks an entry's frame and words: while it waits for a decision, and once it is rejected (redix-app #90).
  bool get isMarked => this == pendingApproval || this == rejected;

  /// Its color: orange while it waits, the theme's error color once rejected, and the theme's outline otherwise (redix-app #90, D1).
  Color colorIn(ColorScheme colors) => this == pendingApproval ? Colors.orange.shade700 : this == rejected ? colors.error : colors.outlineVariant;

  /// The side of an entry's frame: its color, a little heavier where it marks the entry (D5); [BorderSide.none], the frame's own outline, otherwise.
  BorderSide sideIn(ColorScheme colors) => isMarked ? BorderSide(color: colorIn(colors), width: 1.5) : BorderSide.none;
}
