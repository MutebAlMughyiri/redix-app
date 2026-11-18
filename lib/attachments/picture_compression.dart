// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A picture must be smaller than this many bytes to be kept (NFR-06): 1 MB, as the API counts it.
const pictureLimitBytes = 1000000;

const _longestSide = 2000;
const _qualities = [85, 70, 55, 40];

/// [picture] made smaller than [pictureLimitBytes], keeping its text readable: as it is if it already is, otherwise a JPEG at most 2000 pixels long, at the best quality that fits, and only then with fewer pixels.
/// Throws a [FormatException] for what is not a picture.
Uint8List compressedPicture(Uint8List picture) {
  if (picture.length < pictureLimitBytes) {
    return picture;
  }
  final decoded = img.decodeImage(picture);
  if (decoded == null) {
    throw const FormatException('Not a picture');
  }
  var image = img.bakeOrientation(decoded);
  if (image.width > _longestSide || image.height > _longestSide) {
    image = image.width > image.height ? img.copyResize(image, width: _longestSide) : img.copyResize(image, height: _longestSide);
  }
  while (true) {
    for (final quality in _qualities) {
      final compressed = img.encodeJpg(image, quality: quality);
      if (compressed.length < pictureLimitBytes) {
        return compressed;
      }
    }
    image = img.copyResize(image, width: image.width * 3 ~/ 4);
  }
}
