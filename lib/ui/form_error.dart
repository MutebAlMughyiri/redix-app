// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import 'refusal_text.dart';

/// A form's error (redix-app #98, the owner, 12 Nov 2026, D1 = A): the one line above a form's first field saying why it was refused, in the refusal color, brought to the top
/// of the view when it appears or changes, since the form may be scrolled to its buttons (R4). Every form, dialog and sheet shows its error through it, first, so where an
/// error stands is decided here (D3); what a list action says stays a snack bar (D2).
class FormError extends StatefulWidget {
  /// The error [text], keyed [textKey].
  const FormError({super.key, required this.text, required this.textKey});

  /// What is said.
  final String text;

  /// The key of the words that say it.
  final Key textKey;

  @override
  State<FormError> createState() => _FormErrorState();
}

class _FormErrorState extends State<FormError> {
  @override
  void initState() {
    super.initState();
    _bringIntoView();
  }

  @override
  void didUpdateWidget(FormError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _bringIntoView();
    }
  }

  void _bringIntoView() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
    }
  });

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: refusalText(context, widget.text, widget.textKey));
}
