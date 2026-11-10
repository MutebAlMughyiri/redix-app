import 'package:flutter/material.dart';

import 'refusal_text.dart';

/// A refusal under a long form's main button, which brings itself into view when it appears: that button can sit at the very bottom of the screen, and a line below it would then never be seen.
class FormRefusal extends StatefulWidget {
  /// The refusal [text], keyed [textKey].
  const FormRefusal({super.key, required this.text, required this.textKey});

  /// What is said.
  final String text;

  /// The key of the words that say it.
  final Key textKey;

  @override
  State<FormRefusal> createState() => _FormRefusalState();
}

class _FormRefusalState extends State<FormRefusal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  @override
  Widget build(BuildContext context) => refusalText(context, widget.text, widget.textKey);
}
