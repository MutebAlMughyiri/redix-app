import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redix/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => config.apply({}));

  test('UC-070: the values the API answers are taken, and kept for the next start', () async {
    SharedPreferences.setMockInitialValues({});
    final api = MockClient((request) async => http.Response(jsonEncode({'requestTimeoutSeconds': '10', 'fileTimeoutSeconds': '120'}), 200));
    final read = AppConfig();

    await http.runWithClient(read.refresh, () => api);
    final next = AppConfig();
    await next.restore();

    expect((read.requestTimeout, read.fileTimeout), (const Duration(seconds: 10), const Duration(seconds: 120)));
    expect((next.requestTimeout, next.fileTimeout), (const Duration(seconds: 10), const Duration(seconds: 120)));
  });

  test('UC-070: without a network the kept values stay', () async {
    SharedPreferences.setMockInitialValues({'config': jsonEncode({'requestTimeoutSeconds': '15', 'fileTimeoutSeconds': '90'})});
    final kept = AppConfig();
    await kept.restore();

    await http.runWithClient(kept.refresh, () => MockClient((request) async => throw const SocketExceptionLike()));

    expect(kept.requestTimeout, const Duration(seconds: 15));
  });

  testWidgets('UC-070: a request with no answer is given up after its time, a file after its own', (tester) async {
    config.apply({'requestTimeoutSeconds': '10', 'fileTimeoutSeconds': '120'});
    var request = false;
    var file = false;
    unawaited(timed(Completer<void>().future).catchError((Object _) => request = true));
    unawaited(timed(Completer<void>().future, file: true).catchError((Object _) => file = true));

    await tester.pump(const Duration(seconds: 9));
    expect((request, file), (false, false));
    await tester.pump(const Duration(seconds: 2));
    expect((request, file), (true, false));
    await tester.pump(const Duration(seconds: 110));
    expect(file, isTrue);
  });

  testWidgets('UC-070: before the config was ever read a request waits as long as the phone lets it', (tester) async {
    var gaveUp = false;
    unawaited(timed(Completer<void>().future).catchError((Object _) => gaveUp = true));

    await tester.pump(const Duration(minutes: 10));

    expect(gaveUp, isFalse);
  });
}

/// A network failure as the phone reports one.
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
