import 'package:flutter/material.dart';

import '../words/words.dart';
import 'api_list_body.dart';
import 'part_keys.dart';
import 'screen_message.dart';

/// Why something could not be read, and a way to try again: the one look a list and an object both show (findings row 166).
class LoadFailure extends StatelessWidget {
  /// Says the word [message], and offers [onRetry].
  const LoadFailure({super.key, required this.message, required this.onRetry});

  /// The word key of why it could not be read.
  final String message;

  /// Reads it again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ScreenMessage(
      words.text(message),
      textKey: ApiListBody.messageKey,
      action: OutlinedButton(key: ApiListBody.retryKey, onPressed: onRetry, child: Text(words.commonRetry, key: ApiListBody.retryKey.label)),
    );
  }
}
