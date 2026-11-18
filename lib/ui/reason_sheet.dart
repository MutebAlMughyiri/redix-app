// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'form_error.dart';
import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';
import 'app_color.dart';
import 'act_once.dart';

/// Asks why, then does what needs a reason: rejecting an entry (AC-19.1) or reversing one (FR-50). The one owner of that sheet: its quick reasons, its saving, and the refusal it keeps
/// on screen (findings row 166).
class ReasonSheet extends StatefulWidget {
  /// The sheet titled [title], saying [about], asking for the reason under [reasonLabel], offering [quickReasons] when there are any, and sending through [onSend], which answers an
  /// empty string once done, otherwise the word key of the refusal.
  const ReasonSheet({
    super.key,
    required this.title,
    required this.about,
    required this.reasonLabel,
    required this.sendLabel,
    required this.onSend,
    this.reasonHint = '',
    this.quickReasons = const [],
  });

  /// The title.
  static const titleKey = Key('reasonSheet.title');

  /// What the reason is about.
  static const aboutKey = Key('reasonSheet.about');

  /// The heading of the quick reasons.
  static const quickReasonHeadingKey = Key('reasonSheet.quickReasonHeading');

  /// The quick reason at [index].
  static Key quickReasonKey(int index) => Key('reasonSheet.quickReason.$index');

  /// The field holding why.
  static const reasonKey = Key('reasonSheet.reason');

  /// Why it was refused.
  static const messageKey = Key('reasonSheet.message');

  /// The button sending it.
  static const sendKey = Key('reasonSheet.send');

  /// Opens [sheet] over [context].
  static void show(BuildContext context, ReasonSheet sheet) =>
      showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => sheet);

  /// The title.
  final String title;

  /// What the reason is about: what the action does, or the entry it is for.
  final String about;

  /// The reason field's label.
  final String reasonLabel;

  /// What the reason field asks for; empty for nothing.
  final String reasonHint;

  /// Reasons a tap writes in the field; none shows no heading.
  final List<String> quickReasons;

  /// The send button's label.
  final String sendLabel;

  /// Does it, saying why.
  final Future<String> Function(String reason) onSend;

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  final _reason = TextEditingController();
  var _message = '';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _message = '');
    final refusal = await widget.onSend(_reason.text);
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
            Text(widget.title, key: ReasonSheet.titleKey, style: theme.textTheme.titleLarge),
            Text(widget.about, key: ReasonSheet.aboutKey),
            if (_message.isNotEmpty) FormError(text: words.text(_message), textKey: ReasonSheet.messageKey),
            if (widget.quickReasons.isNotEmpty) ...[
              Text(words.approvalsQuickReason, key: ReasonSheet.quickReasonHeadingKey, style: theme.textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final (index, reason) in widget.quickReasons.indexed)
                    ActionChip(key: ReasonSheet.quickReasonKey(index), label: Text(reason, key: ReasonSheet.quickReasonKey(index).label), onPressed: () => setState(() => _reason.text = reason)),
                ],
              ),
            ],
            TextField(
              key: ReasonSheet.reasonKey,
              controller: _reason,
              maxLines: 3,
              decoration: InputDecoration(labelText: widget.reasonLabel, helperText: widget.reasonHint.isEmpty ? null : widget.reasonHint, helperMaxLines: 3),
            ),
            ActOnce(builder: (once) => FilledButton(
              key: ReasonSheet.sendKey,
              style: FilledButton.styleFrom(backgroundColor: AppColor.refusal.of(context), foregroundColor: AppColor.onRefusal.of(context)),
              onPressed: once(_send),
              child: Text(widget.sendLabel, key: ReasonSheet.sendKey.label),
            )),
          ],
        ),
      ),
    );
  }
}
