import 'package:flutter/material.dart';

import '../ui/reason_sheet.dart';
import '../words/words.dart';

/// Reversing something approved (FR-50): the reason sheet, with the reversal's words.
abstract final class ReverseSheet {
  /// The field holding why.
  static const reasonKey = ReasonSheet.reasonKey;

  /// The button reversing it.
  static const sendKey = ReasonSheet.sendKey;

  /// Asks why over [context], then reverses through [onReverse], which answers an empty string once reversed, otherwise the word key of the refusal.
  static void show(BuildContext context, Future<String> Function(String reason) onReverse) {
    final words = Words.of(context);
    ReasonSheet.show(
      context,
      ReasonSheet(title: words.entriesReverseTitle, about: words.entriesReverseExplain, reasonLabel: words.entriesReverseReason, sendLabel: words.entriesReverse, onSend: onReverse),
    );
  }
}
