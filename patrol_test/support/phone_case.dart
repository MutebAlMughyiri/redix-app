import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'made_up_invoice.dart';
import 'pc.dart';
import 'phone_screens.dart';

/// One test case on the phone.
class _PhoneCase {
  const _PhoneCase(this.name, this.body, {required this.skip});

  final String name;
  final Future<void> Function(PatrolIntegrationTester $) body;
  final bool skip;
}

var _cases = <_PhoneCase>[];

/// One business use case: its cases run one after another in the one open app, each signing out with the real button before the next signs in (Muteb, 9 Nov 2026: "dont close and kill app every time").
/// A case that fails leaves a picture and its reason on the PC, and the next case still runs.
void phoneClass(String name, void Function() register) {
  final cases = _cases = <_PhoneCase>[];
  register();
  patrolTest(
    name,
    timeout: const Timeout(Duration(hours: 1)),
    config: const PatrolTesterConfig(existsTimeout: Duration(seconds: 30), visibleTimeout: Duration(seconds: 30)),
    ($) async {
      WidgetsApp.debugAllowBannerOverride = false;
      final failed = <String>[];
      for (final phoneCase in cases) {
        if (phoneCase.skip) {
          await Pc.note('SKIP ${phoneCase.name}');
          continue;
        }
        await Pc.restoreNetwork();
        CameraWithAPicture.reset();
        final clock = Stopwatch()..start();
        try {
          await phoneCase.body($);
          final thrown = $.tester.takeException();
          if (thrown != null) {
            throw StateError('$thrown');
          }
          await Pc.note('PASS ${clock.elapsed.inSeconds}s ${phoneCase.name}');
        } catch (error) {
          failed.add(phoneCase.name);
          await Pc.restoreNetwork();
          await Pc.note('FAIL ${clock.elapsed.inSeconds}s ${phoneCase.name}: $error');
          await $.takeNativeScreenshot('failure-${_slugOf(phoneCase.name)}');
          await $.backToTheApp();
        }
      }
      expect(failed, isEmpty, reason: '${failed.length} of ${cases.length} cases failed');
    },
  );
}

/// Adds a case to the class being declared.
void phoneCase(String name, Future<void> Function(PatrolIntegrationTester $) body, {bool skip = false}) => _cases.add(_PhoneCase(name, body, skip: skip));

String _slugOf(String name) {
  final slug = name.replaceAll(RegExp('[^A-Za-z0-9]+'), '-');
  return slug.length > 70 ? slug.substring(0, 70) : slug;
}
