// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../ui/reason_sheet.dart';
import '../words/words.dart';
import 'approvals.dart';
import 'pending_approval.dart';
import '../format/parts_line.dart';

/// Rejecting an entry, saying why (AC-19.1): the reason sheet, with the entry it is about and the quick reasons; the reason returns to who entered it.
abstract final class RejectSheet {
  /// Asks why over [context], then rejects [entry] through [approvals].
  static void show(BuildContext context, PendingApproval entry, Approvals approvals) {
    final words = Words.of(context);
    ReasonSheet.show(
      context,
      ReasonSheet(
        title: words.approvalsRejectTitle,
        about: partsLine([entry.title, entry.supplierName, formatMoney(entry.amount)]),
        quickReasons: [words.approvalsReasonUnclear, words.approvalsReasonAmount, words.approvalsReasonItem, words.approvalsReasonDuplicate],
        reasonLabel: words.approvalsReason,
        reasonHint: words.approvalsReasonHint,
        sendLabel: words.approvalsRejectSend,
        onSend: (reason) => approvals.reject(entry.id, reason),
      ),
    );
  }
}
