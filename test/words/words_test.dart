// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redix/words/words.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  http.Response bundle(Map<String, String> words, String etag) =>
      http.Response.bytes(utf8.encode(jsonEncode(words)), 200, headers: {'etag': etag});

  Future<Words> load(String language, MockClient client) => http.runWithClient(() => Words.load(language), () => client);

  Future<Map<String, dynamic>> kept() async =>
      jsonDecode((await SharedPreferences.getInstance()).getString('words') ?? '{}') as Map<String, dynamic>;

  test('a language the phone does not have is fetched from the API and kept', () async {
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.path);
      return bundle({'app.title': 'REDIX'}, '"v1"');
    });

    final words = await load('ar', client);

    expect(words.appTitle, 'REDIX');
    expect(requested, ['/translations/ar']);
    expect(await kept(), {'language': 'ar', 'etag': '"v1"', 'words': {'app.title': 'REDIX'}});
  });

  test('the phone keeps only the language in use', () async {
    final client = MockClient((request) async => bundle({'app.title': request.url.pathSegments.last}, '"v1"'));

    await load('ar', client);
    await load('en', client);

    expect(await kept(), {'language': 'en', 'etag': '"v1"', 'words': {'app.title': 'en'}});
  });

  test('a kept language shows at once and is refreshed with its version tag', () async {
    SharedPreferences.setMockInitialValues({'words': '{"language": "ar", "etag": "\\"v1\\"", "words": {"app.title": "kept"}}'});
    final sentTags = <String?>[];
    final client = MockClient((request) async {
      sentTags.add(request.headers['If-None-Match']);
      return http.Response('', 304);
    });

    final words = await load('ar', client);
    await pumpEventQueue();

    expect(words.appTitle, 'kept');
    expect(sentTags, ['"v1"']);
  });

  test('findings row 133: newer words fetched in the background are reported, so the screen shows them without a restart', () async {
    SharedPreferences.setMockInitialValues({'words': '{"language": "ar", "etag": "\\"v1\\"", "words": {"app.title": "kept"}}'});
    var refreshed = 0;
    final client = MockClient((request) async => bundle({'app.title': 'kept', 'categories.tables': 'جداول البند'}, '"v2"'));

    final words = await http.runWithClient(() => Words.load('ar', onRefreshed: () => refreshed++), () => client);
    await pumpEventQueue();

    expect(words.text('categories.tables'), 'categories.tables');
    expect(refreshed, 1);
    expect((await kept())['words'], {'app.title': 'kept', 'categories.tables': 'جداول البند'});
  });

  test('the same words fetched again, or none, never ask for a reload', () async {
    SharedPreferences.setMockInitialValues({'words': '{"language": "ar", "etag": "", "words": {"app.title": "kept"}}'});
    var refreshed = 0;
    final unchanged = MockClient((request) async => bundle({'app.title': 'kept'}, ''));
    final notModified = MockClient((request) async => http.Response('', 304));

    await http.runWithClient(() => Words.load('ar', onRefreshed: () => refreshed++), () => unchanged);
    await pumpEventQueue();
    await http.runWithClient(() => Words.load('ar', onRefreshed: () => refreshed++), () => notModified);
    await pumpEventQueue();

    expect(refreshed, 0);
  });

  test('without a network and nothing kept, the words are empty', () async {
    final words = await load('ar', MockClient((request) async => throw http.ClientException('offline')));

    expect(words.isEmpty, isTrue);
  });

  test('without a network, the words of another language are never shown', () async {
    SharedPreferences.setMockInitialValues({'words': '{"language": "ar", "etag": "", "words": {"app.title": "عربي"}}'});

    final words = await load('en', MockClient((request) async => throw http.ClientException('offline')));

    expect(words.isEmpty, isTrue);
  });

  test('a key missing from the words shows the key itself', () {
    expect(Words({}).text('home.missing'), 'home.missing');
  });
}
