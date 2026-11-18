// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

/// What a kept file is, by its content type, and the icon that shows it: the one owner of "is it a picture or a PDF" for whatever opens or lists a file.
enum FileKind {
  /// A picture, shown to zoom into.
  picture(Icons.image_outlined),

  /// A PDF, handed to the phone.
  pdf(Icons.picture_as_pdf_outlined),

  /// Any other file, handed to the phone.
  other(Icons.description_outlined);

  const FileKind(this.icon);

  /// The icon that shows a file of this kind.
  final IconData icon;

  /// The kind of a file holding [contentType].
  static FileKind of(String contentType) => contentType.startsWith('image/') ? picture : (contentType == 'application/pdf' ? pdf : other);
}
