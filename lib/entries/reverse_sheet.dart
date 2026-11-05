import 'package:flutter/material.dart';

import '../words/words.dart';

/// Asks why something approved is reversed (FR-50), and reverses it.
class ReverseSheet extends StatefulWidget {
  /// The sheet reversing through [onReverse], which answers an empty string once reversed, otherwise the word key of the refusal.
  const ReverseSheet({super.key, required this.onReverse});

  /// The field holding why.
  static const reasonKey = Key('entries.reverseReason');

  /// The button reversing it.
  static const sendKey = Key('entries.reverseSend');

  /// Opens the sheet over [context].
  static void show(BuildContext context, Future<String> Function(String reason) onReverse) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => ReverseSheet(onReverse: onReverse));
  }

  /// Reverses it, saying why.
  final Future<String> Function(String reason) onReverse;

  @override
  State<ReverseSheet> createState() => _ReverseSheetState();
}

class _ReverseSheetState extends State<ReverseSheet> {
  final _reason = TextEditingController();
  var _message = '';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reverse() async {
    final refusal = await widget.onReverse(_reason.text);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _message = refusal);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(words.entriesReverseTitle, style: theme.textTheme.titleLarge),
            Text(words.entriesReverseExplain),
            TextField(
              key: ReverseSheet.reasonKey,
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(labelText: words.entriesReverseReason, border: const OutlineInputBorder()),
            ),
            if (_message.isNotEmpty) Text(words.text(_message), style: TextStyle(color: theme.colorScheme.error)),
            FilledButton(key: ReverseSheet.sendKey, onPressed: _reverse, child: Text(words.entriesReverse)),
          ],
        ),
      ),
    );
  }
}
