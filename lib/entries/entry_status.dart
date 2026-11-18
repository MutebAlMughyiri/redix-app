// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/app_color.dart';

/// Where an entry stands, named as the API names it (findings row 163), and the color that says so: a row shows its status by its frame's color alone (Muteb, 9 Nov 2026).
enum EntryStatus {
  /// Saved by who entered it, and seen by nobody's inbox; its frame is the app's own color.
  draft(AppColor.brand),

  /// Waiting for a decision; its frame is orange (redix-app #90).
  pendingApproval(AppColor.waiting),

  /// Approved: it counts in every total, and never changes again; its frame is a card's own.
  approved(AppColor.frame),

  /// Rejected, with a reason, to be fixed and sent again; its frame is red (redix-app #90).
  rejected(AppColor.refusal);

  const EntryStatus(this.color);

  /// Its color.
  final AppColor color;

  /// The key of the word that says it.
  String get wordKey => 'entries.$name';

  /// Whether its color marks an entry's frame and words: everything not approved yet.
  bool get isMarked => this != approved;

  /// The side of an entry's frame in the theme of [context]: its color, a little heavier where it marks the entry (redix-app #90, D5); [BorderSide.none], the frame's own
  /// outline, once approved.
  BorderSide sideIn(BuildContext context) => isMarked ? BorderSide(color: color.of(context), width: 1.5) : BorderSide.none;
}
