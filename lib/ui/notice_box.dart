// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import 'app_color.dart';

/// A short notice in the screen's flow, on the notice surface: that a code was sent, or that an account falls short of what waits on it. The one look of a notice box.
class NoticeBox extends StatelessWidget {
  /// The notice [text], keyed [textKey], written in [style] over the screen's own text.
  const NoticeBox({super.key, required this.text, required this.textKey, this.style = const TextStyle()});

  /// What it says.
  final String text;

  /// The key of its words.
  final Key textKey;

  /// How its words are written over the screen's own text; as that text when nothing is given.
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColor.noticeSurface.of(context), borderRadius: BorderRadius.circular(8)),
    child: Text(text, key: textKey, style: style),
  );
}
