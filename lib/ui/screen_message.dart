import 'package:flutter/material.dart';

/// What a screen says instead of its content: nothing yet, could not read, not found. It stands at the top and starts on the language's side, never mid-screen
/// (redix-app #96), with [action], such as Retry, under it.
class ScreenMessage extends StatelessWidget {
  /// Says [text], found by tests through [textKey], with [action] under it.
  const ScreenMessage(this.text, {super.key, required this.textKey, this.action = const SizedBox.shrink()});

  /// The words.
  final String text;

  /// The key of the words.
  final Key textKey;

  /// What can be done about it, under the words.
  final Widget action;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [Text(text, key: textKey), action],
      ),
    ),
  );
}
