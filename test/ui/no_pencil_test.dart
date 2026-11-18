// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redix-app #102: no screen draws a pencil button; what can be done to a thing is in its ⋮ menu', () {
    final pencil = RegExp(r'IconButton\((?:(?!IconButton\(|BottomButton\(|bottomNavigationBar).){0,300}?Icons\.edit\w*', dotAll: true);
    final drawn = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')))
        if (pencil.hasMatch(file.readAsStringSync())) file.path,
    ];

    expect(drawn, isEmpty);
  });
}
