// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

/// A screen's title in the app bar, with what it belongs to on a line beneath, so a long title on a narrow phone never cuts the name to a letter.
class ScreenTitle extends StatelessWidget {
  /// The [title] of a screen about [subject], such as the project's name.
  const ScreenTitle(this.title, {required this.subject, super.key});

  /// What the screen is.
  final String title;

  /// What it belongs to.
  final String subject;

  /// The screen's title.
  static const titleKey = Key('screen.title');

  /// What the screen belongs to.
  static const subjectKey = Key('screen.subject');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, key: titleKey, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(subject, key: subjectKey, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
