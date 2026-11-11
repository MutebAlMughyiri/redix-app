import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/number_format.dart';
import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/api_object_body.dart';
import '../ui/part_keys.dart';
import '../ui/title_bar_add.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'capital.dart';
import 'movements_screen.dart';
import 'partner.dart';
import 'partner_dialog.dart';
import 'partner_history_screen.dart';
import 'partner_menu.dart';
import 'partners.dart';
import '../ui/amount_line.dart';

/// A project's partners and capital (UC-016, UC-044): the total, each line the user may see with its own account, balance and share, and a way into its movements. Whoever keeps the
/// settings adds and renames them and sets whose account each is; who sees each is ticked on people's permissions (BR-31, redix-api #106). A partner at zero capital with nothing waiting is deleted from their ⋮ menu, and stays in the
/// history (redix-api #100).
class PartnersScreen extends StatefulWidget {
  /// The screen, showing and changing the [partners] of [project], choosing each one's account among [members].
  const PartnersScreen({super.key, required this.project, required this.partners, required this.members, required this.capital});

  /// Their capital and shares.
  final Capital capital;

  /// The project they belong to.
  final Project project;

  /// The partners this screen shows and changes.
  final Partners partners;

  /// The project's people, one of whom may be a partner's own account.
  final Members members;

  /// The screen's route.
  static const path = '/projects/:projectId/partners';

  /// The route of the partners of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/partners';

  /// The total capital.
  static const totalKey = Key('partners.total');

  /// The balance of the partner [id].
  static Key balanceKey(String id) => Key('partners.balance.$id');

  /// The share of the partner [id].
  static Key shareKey(String id) => Key('partners.share.$id');

  /// The + in the title bar that adds a partner (redix-app #101).
  static const addKey = Key('partners.add');

  /// The title bar's History, opening the partners' history (redix-app #101).
  static const historyKey = Key('partners.history');

  /// The name, in the dialog.
  static const partnerNameKey = Key('partners.partnerName');

  /// The partner's own account, in the dialog.
  static const loginKey = Key('partners.login');

  /// The line that says what the account is for, in the dialog.
  static const loginHintKey = Key('partners.loginHint');

  /// The account of the partner [id], or that they have none.
  static Key detailsKey(String id) => Key('partners.details.$id');

  /// The name of the partner [id].
  static Key nameKey(String id) => Key('partners.name.$id');

  /// The ⋮ menu of the partner [id] (redix-api #100).
  static Key menuKey(String id) => Key('partners.menu.$id');

  /// Edit, in a partner's menu.
  static const editKey = Key('partners.edit');

  /// Delete, in a partner's menu; gray with the reason unless the partner may be deleted.
  static const deleteKey = Key('partners.delete');

  /// The row of the partner [id].
  static Key rowKey(String id) => Key('partners.row.$id');

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
    key: PartnersScreen.totalKey.card,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ApiObjectBody(
        object: widget.capital,
        builder: (figures) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            amountLine(PartnersScreen.totalKey, words.capitalTotal, figures.total, amountStyle: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ),
  );

  Widget _row(Partner partner) {
    final words = Words.of(context);
    final project = widget.project;
    return Card.outlined(
      key: PartnersScreen.rowKey(partner.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListenableBuilder(
        listenable: widget.capital,
        builder: (context, _) {
          final line = widget.capital.value.of(partner.id);
          return ListTile(
            key: PartnersScreen.rowKey(partner.id).body,
            onTap: () => context.push(MovementsScreen.pathOf(project.id, partner.id, partner.name), extra: project),
            title: Text(partner.name, key: PartnersScreen.nameKey(partner.id)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner.userName.isNotEmpty ? partner.userName : words.partnersNoLogin, key: PartnersScreen.detailsKey(partner.id)),
                Text('${formatShare(line.sharePercent)}%', key: PartnersScreen.shareKey(partner.id)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatMoney(line.balance), key: PartnersScreen.balanceKey(partner.id), style: Theme.of(context).textTheme.titleSmall),
                if (project.mayManageSettings) PartnerMenu(project: project, partner: partner, partners: widget.partners, onEdit: () => _ask(partner)),
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
      appBar: AppBar(
        title: ScreenTitle(words.partnersTitle, subject: project.name),
        actions: [
          TitleBarAdd(buttonKey: PartnersScreen.addKey, tooltip: words.partnersNew, onPressed: project.mayManageSettings ? () => _ask(Partner.none()) : null),
          IconButton(
            key: PartnersScreen.historyKey,
            tooltip: words.partnersHistory,
            icon: Icon(Icons.history, key: PartnersScreen.historyKey.icon),
            onPressed: () => context.push(PartnerHistoryScreen.pathOf(project.id), extra: project),
          ),
        ],
      ),
      body: ApiListBody(
        list: widget.partners,
        emptyText: words.partnersEmpty,
        alsoRefresh: widget.capital.load,
        listOf: (items) => ListView(padding: ApiListBody.padding, physics: ApiListBody.physics, children: [_total(words), ...items]),
        itemBuilder: _row,
      ),
    );
  }
}
