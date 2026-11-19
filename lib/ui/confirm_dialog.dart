// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';
import 'app_color.dart';

/// Asks before a change that deserves a second thought: what it applies to, what it means, and a button to go ahead, red when going ahead destroys
/// something (findings row 276).
class ConfirmDialog extends StatelessWidget {
  /// The question [title] about [subject], explained by [explanation]. The [confirmLabel] button closes the dialog and calls [onConfirm]; it is
  /// red when it [destroys].
  const ConfirmDialog({
    super.key,
    required this.title,
    this.subject = '',
    required this.explanation,
    required this.confirmLabel,
    required this.onConfirm,
    this.destroys = false,
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

  /// Whether going ahead destroys something, a delete, a retrieve over the project or closing it, so its button is red (Muteb, 19 Nov 2026).
  final bool destroys;

  /// What the question is about.
  static const subjectKey = Key('confirm.subject');

  /// The dialog.
  static const dialogKey = Key('confirm.dialog');

  /// Its title.
  static const titleKey = Key('confirm.title');

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
      key: dialogKey,
      title: Text(title, key: titleKey),
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
        TextButton(key: cancelKey, onPressed: navigator.pop, child: Text(Words.of(context).commonCancel, key: cancelKey.label)),
        FilledButton(
          key: confirmKey,
          style: destroys ? FilledButton.styleFrom(backgroundColor: AppColor.refusal.of(context)) : null,
          onPressed: () {
            navigator.pop();
            onConfirm();
          },
          child: Text(confirmLabel, key: confirmKey.label),
        ),
      ],
    );
  }
}
