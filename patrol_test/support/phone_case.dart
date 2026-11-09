import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

import 'pc.dart';

/// One test case on the phone: the one wrapper of `patrolTest`, so every case has the same patience, starts with the network on, and leaves a picture of the phone when it fails (Muteb, 7 Nov 2026).
void phoneCase(String name, Future<void> Function(PatrolIntegrationTester $) body, {bool skip = false}) {
  patrolTest(
    name,
    skip: skip,
    config: const PatrolTesterConfig(existsTimeout: Duration(seconds: 30), visibleTimeout: Duration(seconds: 30)),
    ($) async {
      WidgetsApp.debugAllowBannerOverride = false;
      await Pc.restoreNetwork();
      try {
        await body($);
      } catch (_) {
        await $.takeNativeScreenshot('failure');
        rethrow;
      }
    },
  );
}
