import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../projects/project.dart';
import '../ui/confirm_dialog.dart';
import '../ui/messages.dart';
import '../ui/row_menu.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'partner.dart';
import 'partners.dart';
import 'partners_screen.dart';

/// What can be done to a partner, for whoever keeps the settings: their ⋮ menu, as an account's (Muteb, 11 Nov 2026: no pencil, no red bar). Delete stays in it gray, saying why,
/// and whose draft holds them, unless the partner is at zero capital with nothing waiting and no one else's draft (redix-api #100); the person's own drafts naming them are
/// listed when Delete asks, since they go with them (findings row 199), so Delete also needs Delete entries while there are some (findings row 202).
class PartnerMenu extends StatelessWidget {
  /// The menu of [partner] in [project], changed through [partners], opening their dialog through [onEdit].
  const PartnerMenu({super.key, required this.project, required this.partner, required this.partners, required this.onEdit});

  /// The project, which says whether the person may delete entries.
  final Project project;

  /// The partner.
  final Partner partner;

  /// The way to change them.
  final Partners partners;

  /// Opens the partner's dialog.
  final VoidCallback onEdit;

  void _askToDelete(BuildContext context) {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.partnersDeleteQuestion,
        subject: partner.name,
        explanation: [
          words.partnersDeleteKeepsMovements,
          if (partner.myDrafts.isNotEmpty) [words.partnersDeleteRemovesMyDrafts, for (final draft in partner.myDrafts) partsLine([formatDate(draft.entryDate), formatMoney(draft.amount)])].join('\n'),
        ].join('\n\n'),
        confirmLabel: words.partnersDelete,
        onConfirm: () async {
          final refusal = await partners.delete(partner);
          showMessage(messenger, words, refusal.isEmpty ? 'partners.deleted' : refusal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return rowMenu(PartnersScreen.menuKey(partner.id), [
      rowMenuItem(PartnersScreen.editKey, words.partnersEdit, onEdit),
      rowMenuItem(PartnersScreen.deleteKey, words.partnersDelete, () => _askToDelete(context), reason: partner.mayDelete
            ? ''
            : partsLine([
                words.partnersPartnerNotDeletable,
                if (partner.othersDrafts.isNotEmpty) words.partnersDraftsBy.fill([partsLine(partner.othersDrafts)]),
                if (partner.myDrafts.isNotEmpty && !project.mayDeleteEntries) words.partnersMyDraftsNeedDeleteEntries,
              ])),
    ]);
  }
}
