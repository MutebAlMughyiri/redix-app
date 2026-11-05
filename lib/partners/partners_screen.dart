import 'package:flutter/material.dart';

import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'partner.dart';
import 'partner_dialog.dart';
import 'partners.dart';

/// A project's partners (UC-016): whoever keeps the settings adds and renames them, and links each to their login, so they see their own capital (BR-31). Nothing is deleted.
class PartnersScreen extends StatefulWidget {
  /// The screen, showing and changing the [partners] of [project], choosing a login among [members].
  const PartnersScreen({super.key, required this.project, required this.partners, required this.members});

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

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(title: Text('${words.partnersTitle} · ${project.name}')),
      floatingActionButton: project.mayManageSettings
          ? FloatingActionButton.extended(key: PartnersScreen.addKey, icon: const Icon(Icons.add), label: Text(words.partnersNew), onPressed: () => _ask(Partner.none()))
          : null,
      body: ApiListBody(
        list: widget.partners,
        emptyText: words.partnersEmpty,
        itemBuilder: (partner) => Card.outlined(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(partner.name, key: PartnersScreen.nameKey(partner.id)),
            subtitle: Text(partner.userName.isEmpty ? words.partnersNoLogin : partner.userName, key: PartnersScreen.detailsKey(partner.id)),
            trailing: project.mayManageSettings
                ? IconButton(key: PartnersScreen.editKey(partner.id), icon: const Icon(Icons.edit_outlined), tooltip: words.partnersEdit, onPressed: () => _ask(partner))
                : null,
          ),
        ),
      ),
    );
  }
}
