import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';

/// Findings row 193: a file read from the phone that holds nothing says it is empty, rather than counting as nothing picked.
void main() {
  test('a file of no bytes is no file, and says it is empty', () {
    final file = PickedFile.read('permit.pdf', '/phone/permit.pdf', Uint8List(0));

    expect(file.isNone, isTrue);
    expect(file.failure, 'attachments.fileEmpty');
  });

  test('a file holding bytes is kept as it was read', () {
    final file = PickedFile.read('permit.pdf', '/phone/permit.pdf', Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));

    expect(file.isNone, isFalse);
    expect((file.name, file.path, file.failure), ('permit.pdf', '/phone/permit.pdf', ''));
  });

  test('going back without choosing is still nothing, with nothing to say', () {
    expect(PickedFile.none().failure, isEmpty);
  });
}
