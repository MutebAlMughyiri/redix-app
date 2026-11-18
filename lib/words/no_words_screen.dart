// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/part_keys.dart';

/// Shown on a first start without a network, when the app has no words yet; it needs none, only an icon and a retry button.
class NoWordsScreen extends StatelessWidget {
  /// The screen, calling [onRetry] when the user retries.
  const NoWordsScreen({super.key, required this.onRetry});

  /// Loads the words again.
  final VoidCallback onRetry;

  /// The no-network icon.
  static const iconKey = Key('noWords.icon');

  /// The retry button.
  static const retryKey = Key('noWords.retry');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, key: iconKey, size: 48),
            IconButton(key: retryKey, icon: Icon(Icons.refresh, key: retryKey.icon), onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
