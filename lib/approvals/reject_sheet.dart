import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'approvals.dart';
import 'approvals_screen.dart';
import 'pending_approval.dart';

/// Rejects an entry, saying why (AC-19.1): the reason returns to who entered it.
class RejectSheet extends StatefulWidget {
  /// The sheet rejecting [entry] through [approvals].
  const RejectSheet({super.key, required this.entry, required this.approvals});

  /// The entry.
  final PendingApproval entry;

  /// Where it is decided.
  final Approvals approvals;

  @override
  State<RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<RejectSheet> {
  final _reason = TextEditingController();
  var _message = '';
  var _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reject() async {
    setState(() {
      _saving = true;
      _message = '';
    });
    final refusal = await widget.approvals.reject(widget.entry.id, _reason.text);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final entry = widget.entry;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(words.approvalsRejectTitle, key: ApprovalsScreen.rejectTitleKey, style: theme.textTheme.titleLarge),
            Text([entry.title, if (entry.supplierName.isNotEmpty) entry.supplierName, formatMoney(entry.amount)].join(' · '), key: ApprovalsScreen.rejectEntryKey),
            Text(words.approvalsQuickReason, key: ApprovalsScreen.quickReasonHeadingKey, style: theme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final (index, reason) in [words.approvalsReasonUnclear, words.approvalsReasonAmount, words.approvalsReasonItem, words.approvalsReasonDuplicate].indexed)
                  ActionChip(key: ApprovalsScreen.quickReasonKey(index), label: Text(reason, key: ApprovalsScreen.quickReasonKey(index).label), onPressed: () => setState(() => _reason.text = reason)),
              ],
            ),
            TextField(
              key: ApprovalsScreen.reasonKey,
              controller: _reason,
              maxLines: 3,
              decoration: InputDecoration(labelText: words.approvalsReason, helperText: words.approvalsReasonHint, helperMaxLines: 3, border: const OutlineInputBorder()),
            ),
            if (_message.isNotEmpty) Text(words.text(_message), key: ApprovalsScreen.rejectMessageKey, style: TextStyle(color: theme.colorScheme.error)),
            FilledButton(
              key: ApprovalsScreen.rejectSendKey,
              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
              onPressed: _saving ? null : _reject,
              child: Text(words.approvalsRejectSend, key: ApprovalsScreen.rejectSendKey.label),
            ),
          ],
        ),
      ),
    );
  }
}
