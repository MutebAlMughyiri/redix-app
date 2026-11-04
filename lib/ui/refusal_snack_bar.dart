import 'package:flutter/material.dart';

import '../words/words.dart';

/// Waits for [change], which answers an empty string once made, otherwise the word key of the refusal, and shows a refusal in a SnackBar.
Future<void> showRefusalOf(BuildContext context, Future<String> change) async {
  final words = Words.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final refusal = await change;
  if (refusal.isNotEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(words.text(refusal))));
  }
}
