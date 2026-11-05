import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:redix/attachments/picture_compression.dart';

void main() {
  /// A picture as a phone's camera gives it: large, and full of detail no JPEG can squeeze away.
  Uint8List aPhoto(int width, int height) {
    final random = Random(1);
    final photo = img.Image(width: width, height: height);
    for (final pixel in photo) {
      pixel
        ..r = random.nextInt(256)
        ..g = random.nextInt(256)
        ..b = random.nextInt(256);
    }
    return img.encodeJpg(photo, quality: 95);
  }

  test('AC-10.1: a photo of an invoice comes back under 1 MB', () {
    final photo = aPhoto(2400, 1800);
    expect(photo.length, greaterThan(pictureLimitBytes));

    final compressed = compressedPicture(photo);

    expect(compressed.length, lessThan(pictureLimitBytes));
    expect(img.decodeJpg(compressed), isNotNull);
  });

  test('a picture is at most 2000 pixels long, so the text stays readable at the size kept', () {
    final compressed = img.decodeJpg(compressedPicture(aPhoto(2400, 1800)))!;

    expect(max(compressed.width, compressed.height), lessThanOrEqualTo(2000));
  });

  test('a picture already under 1 MB stays exactly as it is', () {
    final small = aPhoto(100, 100);

    expect(compressedPicture(small), same(small));
  });

  test('what is not a picture is refused rather than kept', () {
    expect(() => compressedPicture(Uint8List(pictureLimitBytes)), throwsA(isA<FormatException>()));
  });
}
