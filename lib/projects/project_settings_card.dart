import 'package:flutter/material.dart';

import '../accounts/accounts_screen.dart';
import '../approvals/approvals_screen.dart';
import '../auth/permission.dart';
import '../contracts/contracts_screen.dart';
import '../documents/documents_screen.dart';
import '../home/home_screen.dart';
import '../partners/partners_screen.dart';
import '../reports/item_reports_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/vat_statement_screen.dart';
import '../settings/payment_methods_screen.dart';
import '../structure/categories_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../ui/part_keys.dart';
import '../users/my_permissions_screen.dart';
import '../users/users_screen.dart';
import '../words/words.dart';
import 'project.dart';
import 'project_info_screen.dart';

/// The open project's buttons, with what the signed-in user's permissions allow. The four used most always show, two by two: Contracts, Reports, the item reports and
/// Suppliers. The arrow under them opens the card in place on the rest, and closes it again; it starts closed whenever the app starts (Muteb, 11 Nov 2026): Accounts, Partners, the VAT refund,
/// Approvals and Documents, then the project's own: More info, the user's own permissions, its users, its categories and items, its payment methods, and importing its
/// settings, grayed until it is built. Settings is an icon in the home's top bar. A finished project says first, in one line, that it is read-only (redix-api 93).
class ProjectSettingsCard extends StatefulWidget {
  /// The card of [project], calling [onOpen] with the route of the screen a button opens.
  const ProjectSettingsCard({super.key, required this.project, required this.onOpen});

  /// The project this card shows.
  final Project project;

  /// Opens the screen at a route of the project.
  final ValueChanged<String> onOpen;

  @override
  State<ProjectSettingsCard> createState() => _ProjectSettingsCardState();
}

class _ProjectSettingsCardState extends State<ProjectSettingsCard> {
  var _showsAll = false;

  /// A button opening [path]; an empty path is a screen not built yet, so the button shows grayed.
  Widget _button(Key key, IconData icon, String label, String path) => TextButton.icon(
    key: key,
    style: TextButton.styleFrom(alignment: AlignmentDirectional.centerStart),
    icon: Icon(icon, key: key.icon),
    label: Text(label, key: key.label),
    onPressed: path.isEmpty ? null : () => widget.onOpen(path),
  );

  /// [buttons] two to a row.
  Widget _twoByTwo(List<Widget> buttons) => Column(
    children: [
      for (var index = 0; index < buttons.length; index += 2)
        Row(children: [Expanded(child: buttons[index]), Expanded(child: index + 1 < buttons.length ? buttons[index + 1] : const SizedBox.shrink())]),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final id = project.id;
    return Card.outlined(
      key: HomeScreen.cardKey(id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (project.isFinished) ...[
            ListTile(
              key: HomeScreen.finishedKey(id),
              dense: true,
              leading: Icon(Icons.lock_outline, key: HomeScreen.finishedKey(id).icon),
              title: Text('${words.projectsFinished} · ${words.projectsReadOnly}', key: HomeScreen.finishedKey(id).title),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: _twoByTwo([
              _button(HomeScreen.contractsKey(id), Icons.description_outlined, words.contractsTitle, ContractsScreen.pathOf(id)),
              _button(HomeScreen.reportsKey(id), Icons.summarize_outlined, words.reportsTitle, ReportsScreen.pathOf(id)),
              _button(HomeScreen.itemReportsKey(id), Icons.analytics_outlined, words.reportsRevenueAndExpenses, ItemReportsScreen.pathOf(id)),
              _button(HomeScreen.suppliersKey(id), Icons.storefront_outlined, words.suppliersTitle, SuppliersScreen.pathOf(id)),
            ]),
          ),
          if (_showsAll) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _twoByTwo([
                _button(HomeScreen.accountsKey(id), Icons.account_balance_wallet_outlined, words.accountsTitle, AccountsScreen.pathOf(id)),
                _button(HomeScreen.partnersKey(id), Icons.handshake_outlined, words.partnersTitle, PartnersScreen.pathOf(id)),
                _button(HomeScreen.vatKey(id), Icons.receipt_long_outlined, words.vatTitle, VatStatementScreen.pathOf(id)),
                if (project.may(Permission.approveEntries)) _button(HomeScreen.approvalsKey(id), Icons.fact_check_outlined, words.approvalsTitle, ApprovalsScreen.pathOf(id)),
                _button(HomeScreen.documentsKey(id), Icons.folder_outlined, words.documentsTitle, DocumentsScreen.pathOf(id)),
                _button(HomeScreen.projectInfoKey(id), Icons.info_outline, words.projectInfoTitle, ProjectInfoScreen.pathOf(id)),
                _button(HomeScreen.myPermissionsKey(id), Icons.verified_user_outlined, words.permissionsMine, MyPermissionsScreen.pathOf(id)),
                if (project.may(Permission.manageUsers)) _button(HomeScreen.usersKey(id), Icons.group_outlined, words.usersTitle, UsersScreen.pathOf(id)),
                if (project.may(Permission.manageStructure)) _button(HomeScreen.categoriesKey(id), Icons.category_outlined, words.categoriesTitle, CategoriesScreen.pathOf(id)),
                if (project.may(Permission.manageSettings)) _button(HomeScreen.paymentMethodsKey(id), Icons.credit_card_outlined, words.paymentMethodsTitle, PaymentMethodsScreen.pathOf(id)),
                _button(HomeScreen.importSettingsKey(id), Icons.file_upload_outlined, words.projectsImportSettings, ''),
              ]),
            ),
          ],
          IconButton(
            key: HomeScreen.moreSettingsKey(id),
            icon: Icon(_showsAll ? Icons.expand_less : Icons.expand_more, key: HomeScreen.moreSettingsKey(id).icon),
            onPressed: () => setState(() => _showsAll = !_showsAll),
          ),
        ],
      ),
    );
  }
}
