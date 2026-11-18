// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const notice = [
  'Copyright 2026 Tech Details. All rights reserved.',
  'Use of this file is governed by the LICENSE file at the root of this repository.',
];

const commentOf = {'.dart': '// ', '.kt': '// ', '.kts': '// ', '.java': '// ', '.swift': '// ', '.ps1': '# ', '.sh': '# '};

const folders = ['lib', 'test', 'patrol_test', 'tool', 'android', 'ios'];

/// Files Patrol and Flutter write for every run or build, which the repo does not keep.
const writtenByTools = ['patrol_test/test_bundle.dart', 'GeneratedPluginRegistrant.', 'ios/Flutter/'];

void main() {
  test('every source file opens with the copyright notice, word for word (redix-api #143 R1, R6)', () {
    final missing = <String>[];
    for (final folder in folders) {
      for (final entity in Directory(folder).listSync(recursive: true)) {
        final path = entity.path.replaceAll(r'\', '/');
        final comment = commentOf[path.substring(path.lastIndexOf('.').clamp(0, path.length))];
        if (entity is! File || comment == null || writtenByTools.any(path.contains) || path.contains('/build/') || path.contains('/.')) continue;
        final lines = entity.readAsLinesSync();
        final start = lines.isNotEmpty && lines.first.startsWith('#!') ? 1 : 0;
        final expected = [for (final line in notice) '$comment$line'];
        if (lines.length < start + expected.length || !listEquals(lines.sublist(start, start + expected.length), expected)) missing.add(path);
      }
    }
    expect(missing, isEmpty, reason: '${missing.length} files open without the notice');
  });
}

bool listEquals(List<String> a, List<String> b) => a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);
