import 'package:flutter/material.dart';

import '../ui/app_color.dart';

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

  /// Its color: waiting while it waits, refusal once rejected, and a card's frame otherwise (redix-app #90, D1).
  AppColor get color => this == pendingApproval ? AppColor.waiting : this == rejected ? AppColor.refusal : AppColor.frame;

  /// The side of an entry's frame in the theme of [context]: its color, a little heavier where it marks the entry (D5); [BorderSide.none], the frame's own outline, otherwise.
  BorderSide sideIn(BuildContext context) => isMarked ? BorderSide(color: color.of(context), width: 1.5) : BorderSide.none;
}
