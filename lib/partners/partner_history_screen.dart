import 'package:flutter/material.dart';

import '../history/history_view.dart';
import '../projects/project.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'partner_history.dart';
import 'partners.dart';

/// السجل, from Partners' title bar (redix-app #101): what was done to the partners the user sees and what moved their capital, newest first, a page at a time; every partner or
/// one, everyone's lines or the signed-in user's own.
class PartnerHistoryScreen extends StatefulWidget {
  /// The [history] of [project]'s [partners].
  const PartnerHistoryScreen({super.key, required this.project, required this.history, required this.partners});

  /// The project.
  final Project project;

  /// Its partner history.
  final PartnerHistory history;

  /// Its partners the user sees, one filter each.
  final Partners partners;

  /// The screen's route.
  static const path = '/projects/:projectId/partners/history';

  /// The route of the partner history of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/partners/history';

  /// The chip opening the list of partners, under the search line.
  static const partnerChoiceKey = Key('partnerHistory.partnerChoice');

  /// Every partner, in that list.
  static const allKey = Key('partnerHistory.all');

  /// The partner [id] alone, in that list.
  static Key partnerKey(String id) => Key('partnerHistory.partner.$id');

  /// The filter showing what the signed-in user did.
  static const mineKey = Key('partnerHistory.mine');

  /// The line [id].
  static Key lineKey(int id) => Key('partnerHistory.line.$id');

  /// The button reading the next page.
  static const moreKey = Key('partnerHistory.more');

  @override
  State<PartnerHistoryScreen> createState() => _PartnerHistoryScreenState();
}

class _PartnerHistoryScreenState extends State<PartnerHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.history.open();
    widget.partners.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final history = widget.history;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.partnersHistory, subject: widget.project.name)),
      body: ListenableBuilder(
        listenable: Listenable.merge([history, widget.partners]),
        builder: (context, _) => HistoryView(
          history: history,
          title: words.partnersHistory,
          choiceLabel: words.historyPartner,
          choices: [for (final partner in widget.partners.all) (partner.id, partner.name)],
          choiceChipKey: PartnerHistoryScreen.partnerChoiceKey,
          allKey: PartnerHistoryScreen.allKey,
          choiceKey: PartnerHistoryScreen.partnerKey,
          mineKey: PartnerHistoryScreen.mineKey,
          lineKey: PartnerHistoryScreen.lineKey,
          moreKey: PartnerHistoryScreen.moreKey,
        ),
      ),
    );
  }
}
