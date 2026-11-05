import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/number_format.dart';
import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/api_object_body.dart';
import '../ui/change_dialog.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'capital.dart';
import 'capital_move_screen.dart';
import 'movements_screen.dart';
import 'partner.dart';
import 'partner_dialog.dart';
import 'partners.dart';

/// A project's partners and capital (UC-016, UC-044): the total, each line the user may see with its balance and share, and a way into its movements. Whoever keeps the settings adds and renames them, and links each to their login, so they see their own capital (BR-31). Nothing is deleted.
class PartnersScreen extends StatefulWidget {
  /// The screen, showing and changing the [partners] of [project], choosing a login among [members].
  const PartnersScreen({super.key, required this.project, required this.partners, required this.members, required this.capital});

  /// Their capital and shares.
  final Capital capital;

  /// The project they belong to.
  final Project project;

  /// The partners this screen shows and changes.
  final Partners partners;

  /// The people who can be a partner's login.
  final Members members;

  /// The screen's route.
  static const path = '/projects/:projectId/partners';

  /// The route of the partners of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/partners';

  /// The total capital.
  static const totalKey = Key('partners.total');

  /// The button that enters a capital movement.
  static const moveKey = Key('partners.move');

  /// The balance of the partner [id].
  static Key balanceKey(String id) => Key('partners.balance.$id');

  /// The share of the partner [id].
  static Key shareKey(String id) => Key('partners.share.$id');

  /// The button that adds a partner.
  static const addKey = Key('partners.add');

  /// The name, in the dialog.
  static const partnerNameKey = Key('partners.partnerName');

  /// The login, in the dialog.
  static const loginKey = Key('partners.login');

  /// The line that says what the login is for, in the dialog.
  static const loginHintKey = Key('partners.loginHint');

  /// The button that saves, in the dialog.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a change was refused, in the dialog.
  static const dialogMessageKey = ChangeDialog.messageKey;

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The line shown while the project has no partners.
  static const emptyKey = ApiListBody.emptyKey;

  /// The name of the partner [id].
  static Key nameKey(String id) => Key('partners.name.$id');

  /// The login of the partner [id], or that they have none.
  static Key detailsKey(String id) => Key('partners.details.$id');

  /// The button that edits the partner [id].
  static Key editKey(String id) => Key('partners.edit.$id');

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  @override
  void initState() {
    super.initState();
    widget.partners.loadOnOpen();
    widget.capital.loadOnOpen();
    if (widget.project.mayManageSettings) {
      widget.members.loadOnOpen();
    }
  }

  void _ask(Partner partner) {
    showDialog<void>(
      context: context,
      builder: (_) => PartnerDialog(partner: partner, partners: widget.partners, members: widget.members),
    );
  }

  Widget _total(Words words) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ApiObjectBody(
        object: widget.capital,
        builder: (figures) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(child: Text(words.capitalTotal)),
                Text(formatMoney(figures.total), key: PartnersScreen.totalKey, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            if (widget.project.mayMoveMoney)
              FilledButton.icon(key: PartnersScreen.moveKey, icon: const Icon(Icons.add), label: Text(words.capitalMovement), onPressed: () => context.push(CapitalMoveScreen.pathOf(widget.project.id), extra: widget.project)),
          ],
        ),
      ),
    ),
  );

  Widget _row(Partner partner) {
    final words = Words.of(context);
    final project = widget.project;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListenableBuilder(
        listenable: widget.capital,
        builder: (context, _) {
          final line = widget.capital.value.of(partner.id);
          return ListTile(
            onTap: () => context.push(MovementsScreen.pathOf(project.id, partner.id, partner.name), extra: project),
            title: Text(partner.name, key: PartnersScreen.nameKey(partner.id)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text([if (partner.userName.isNotEmpty) partner.userName else words.partnersNoLogin, if (!line.isActive) words.capitalLeft].join(' · '), key: PartnersScreen.detailsKey(partner.id)),
                Text('${formatShare(line.sharePercent)}%', key: PartnersScreen.shareKey(partner.id)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatMoney(line.balance), key: PartnersScreen.balanceKey(partner.id), style: Theme.of(context).textTheme.titleSmall),
                if (project.mayManageSettings) IconButton(key: PartnersScreen.editKey(partner.id), icon: const Icon(Icons.edit_outlined), tooltip: words.partnersEdit, onPressed: () => _ask(partner)),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.partnersTitle, subject: project.name)),
      floatingActionButton: project.mayManageSettings
          ? FloatingActionButton.extended(key: PartnersScreen.addKey, icon: const Icon(Icons.add), label: Text(words.partnersNew), onPressed: () => _ask(Partner.none()))
          : null,
      body: ApiListBody(
        list: widget.partners,
        emptyText: words.partnersEmpty,
        listOf: (items) => ListView(padding: ApiListBody.padding, children: [_total(words), ...items]),
        itemBuilder: _row,
      ),
    );
  }
}
