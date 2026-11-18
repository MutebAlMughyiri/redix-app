// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/api.dart';

void main() {
  test('a refusal with a reason of its own shows its word', () {
    expect(refusalOf({'code': 'projectFinished'}, 'entries'), 'entries.projectFinished');
  });

  test('redix-api #150 R7: a bare status carries a code, and shows the refusal word as it did before it had one', () {
    for (final code in statusCodes) {
      expect(refusalOf({'code': code}, 'entries'), 'entries.refused', reason: code);
    }
    expect(refusalOf({}, 'entries'), 'entries.refused');
  });
}
