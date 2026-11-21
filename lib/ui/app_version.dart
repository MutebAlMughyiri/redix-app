// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../words/words.dart';
import 'app_color.dart';

/// The installed app's version, «الإصدار 1.0.0 (abc1234)», quiet at the foot of the sign-in screen and of Shared settings (redix-app #124): the
/// version in pubspec.yaml, which Flutter builds into the app as [appBuildName], so it is the one App Tester and the phone's App info show, and
/// the commit the build was made from, as the web shows its own (the owner, 21 Nov 2026).
class AppVersion extends StatelessWidget {
  /// The line, at the foot of the screen that holds it.
  const AppVersion({super.key});

  /// The line's text, which the tests of both screens read.
  static const lineKey = Key('appVersion.line');

  /// The commit this build was made from, which the build passes as `--dart-define=COMMIT=<its short hash>`, as the test builds do; "" when it
  /// passed none.
  static const builtFrom = String.fromEnvironment('COMMIT');

  /// The line: [word], [version], and [commit] when the build passed one, kept whole inside Arabic.
  static String lineOf(String word, String version, String commit) => commit.isEmpty ? '$word $version' : '$word $version \u2068($commit)\u2069';

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          lineOf(Words.of(context).appVersion, appBuildName ?? '', builtFrom),
          key: lineKey,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColor.quiet.of(context)),
        ),
      );
}
