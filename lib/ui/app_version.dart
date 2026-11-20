// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../words/words.dart';
import 'app_color.dart';

/// The installed app's version, «الإصدار 1.0.0», quiet at the foot of the sign-in screen and of Shared settings (redix-app #124): the
/// version in pubspec.yaml, which Flutter builds into the app as [appBuildName], so it is the one App Tester and the phone's App info show.
class AppVersion extends StatelessWidget {
  /// The line, at the foot of the screen that holds it.
  const AppVersion({super.key});

  /// The line's text, which the tests of both screens read.
  static const lineKey = Key('appVersion.line');

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${Words.of(context).appVersion} ${appBuildName ?? ''}',
          key: lineKey,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColor.quiet.of(context)),
        ),
      );
}
