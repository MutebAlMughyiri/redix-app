import 'package:flutter/material.dart';

import '../words/word_fill.dart';
import '../words/words.dart';
import 'part_keys.dart';

/// The key of the SnackBar saying the word [wordKey]: every message has its own key, made from what it says, so a test finds it by key (Muteb, 7 Nov 2026).
Key messageKeyOf(String wordKey) => Key('message.$wordKey');

/// Shows the word [wordKey] in a SnackBar through [messenger], keyed by [messageKeyOf], with [values] in its `{0}`, `{1}` and on when it has them, and an action named
/// [actionLabel] doing [onAction] when the label is not empty, for [duration].
void showMessage(ScaffoldMessengerState messenger, Words words, String wordKey, {List<String> values = const [], String actionLabel = '', VoidCallback onAction = _nothing, Duration duration = const Duration(milliseconds: 4000)}) => messenger.showSnackBar(
  SnackBar(
    key: messageKeyOf(wordKey),
    content: Text(words.text(wordKey).fill(values), key: messageKeyOf(wordKey).label),
    action: actionLabel.isEmpty ? null : SnackBarAction(key: messageKeyOf(wordKey).icon, label: actionLabel, onPressed: onAction),
    persist: false,
    duration: duration,
  ),
);

void _nothing() {}

/// Waits for [change], which answers an empty string once made, otherwise the word key of the refusal; shows a refusal in a SnackBar, and answers it.
Future<String> showRefusalOf(BuildContext context, Future<String> change) async {
  final words = Words.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final refusal = await change;
  if (refusal.isNotEmpty) {
    showMessage(messenger, words, refusal);
  }
  return refusal;
}
