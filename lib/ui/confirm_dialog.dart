import 'package:flutter/material.dart';

import '../words/words.dart';

/// Asks before a change that deserves a second thought: what it applies to, what it means, and a red button to go ahead.
class ConfirmDialog extends StatelessWidget {
  /// The question [title] about [subject], explained by [explanation]. The [confirmLabel] button closes the dialog and calls [onConfirm].
  const ConfirmDialog({
    super.key,
    required this.title,
    this.subject = '',
    required this.explanation,
    required this.confirmLabel,
    required this.onConfirm,
  });

  /// The question.
  final String title;

  /// What the question is about, such as a project's name; empty when it needs none.
  final String subject;

  /// What going ahead means.
  final String explanation;

  /// The word on the button that goes ahead.
  final String confirmLabel;

  /// What going ahead does.
  final VoidCallback onConfirm;

  /// What the question is about.
  static const subjectKey = Key('confirm.subject');

  /// What going ahead means.
  static const explanationKey = Key('confirm.explanation');

  /// The button that goes ahead.
  static const confirmKey = Key('confirm.confirm');

  /// The button that changes nothing.
  static const cancelKey = Key('confirm.cancel');

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subject.isNotEmpty) ...[
            Text(subject, key: subjectKey, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
          ],
          Text(explanation, key: explanationKey),
        ],
      ),
      actions: [
        TextButton(key: cancelKey, onPressed: navigator.pop, child: Text(Words.of(context).commonCancel)),
        FilledButton(
          key: confirmKey,
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () {
            navigator.pop();
            onConfirm();
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
