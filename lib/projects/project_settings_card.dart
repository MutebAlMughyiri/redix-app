// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../accounts/accounts_screen.dart';
import '../approvals/approvals_screen.dart';
import '../auth/permission.dart';
import '../contracts/contracts_screen.dart';
import '../documents/documents_screen.dart';
import '../history/project_history_screen.dart';
import '../home/home_screen.dart';
import '../partners/partners_screen.dart';
import '../reports/item_reports_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/summary.dart';
import '../settings/payment_methods_screen.dart';
import '../structure/categories_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../ui/app_color.dart';
import '../ui/part_keys.dart';
import '../users/my_permissions_screen.dart';
import '../users/permission_requests_screen.dart';
import '../users/users_screen.dart';
import '../words/words.dart';
import 'project.dart';
import 'project_info_screen.dart';

/// The open project's buttons, with what the signed-in user's permissions allow, four to a page, two by two, swiped sideways page by page with dots under them (Muteb,
/// 11 Nov 2026), going round: on from the last page comes the first, and back from the first the last. The first page holds the four used most: Contracts, Reports, the item reports and Suppliers; then Accounts, Partners, the VAT refund, Approvals and
/// Documents, then the project's own: More info, the user's own permissions, its users, its categories and items, its payment methods, loading its project file (redix-api
/// #132), archiving it and retrieving an archive over it (UC-073). Nothing is kept: the card opens on its first page. Settings is an icon in the home's top bar. A finished project
/// says first, in one line, that it is read-only (redix-api 93).
class ProjectSettingsCard extends StatefulWidget {
  /// The card of [project], calling [onOpen] with the route of the screen a button opens, [onLoadFile] to load a project file, [onArchive] to archive the project and
  /// [onRetrieve] to retrieve an archive over it.
  const ProjectSettingsCard({super.key, required this.project, required this.onOpen, required this.onLoadFile, required this.onArchive, required this.onRetrieve});

  /// The project this card shows.
  final Project project;

  /// Opens the screen at a route of the project.
  final ValueChanged<String> onOpen;

  /// Loads a project file into the project (UC-071).
  final VoidCallback onLoadFile;

  /// Takes the project's archive (UC-073).
  final VoidCallback onArchive;

  /// Retrieves an archive over the project (UC-073).
  final VoidCallback onRetrieve;

  /// How many buttons a page holds.
  static const perPage = 4;

  @override
  State<ProjectSettingsCard> createState() => _ProjectSettingsCardState();
}

class _ProjectSettingsCardState extends State<ProjectSettingsCard> {
  var _page = 0;

  /// Far from both ends, on a multiple of every page count the card can have (one to four), so it opens on the first page and goes round either way.
  final _pages = PageController(initialPage: 12000);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// A button opening [path], gray for an empty path, a screen not built yet, and without [mayOpen], a screen the user may not open (redix-api #131: gray, never
  /// hidden).
  Widget _button(Key key, IconData icon, String label, String path, {bool mayOpen = true}) => _doing(key, icon, label, path.isEmpty || !mayOpen ? null : () => widget.onOpen(path));

  /// The one look of the card's buttons: doing [onPressed], gray when it is null. Its name takes two lines at most.
  Widget _doing(Key key, IconData icon, String label, VoidCallback? onPressed) => TextButton.icon(
    key: key,
    style: TextButton.styleFrom(alignment: AlignmentDirectional.centerStart),
    icon: Icon(icon, key: key.icon),
    label: Text(label, key: key.label, maxLines: 2, overflow: TextOverflow.ellipsis),
    onPressed: onPressed,
  );

  /// [buttons] two to a row, in two rows sharing the page's height.
  Widget _twoByTwo(List<Widget> buttons) => Column(
    children: [
      for (var index = 0; index < ProjectSettingsCard.perPage; index += 2)
        Expanded(
          child: Row(
            children: [
              for (final at in [index, index + 1]) Expanded(child: at < buttons.length ? buttons[at] : const SizedBox.shrink()),
            ],
          ),
        ),
    ],
  );

  /// A row's height: a button's name on two lines at the phone's text size, and the button's own padding above and below.
  double _rowHeight(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge!;
    return MediaQuery.textScalerOf(context).scale(label.fontSize!) * label.height! * 2 + 16;
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final id = project.id;
    final buttons = [
      _button(HomeScreen.contractsKey(id), Icons.description_outlined, words.contractsTitle, ContractsScreen.pathOf(id)),
      _button(HomeScreen.reportsKey(id), Icons.summarize_outlined, words.reportsTitle, ReportsScreen.pathOf(id), mayOpen: project.maySeeReports),
      _button(HomeScreen.itemReportsKey(id, SummarySide.expenses), Icons.trending_down, words.summaryExpenses, ItemReportsScreen.pathOf(id, SummarySide.expenses), mayOpen: project.maySeeReports),
      _button(HomeScreen.itemReportsKey(id, SummarySide.revenue), Icons.trending_up, words.summaryRevenue, ItemReportsScreen.pathOf(id, SummarySide.revenue), mayOpen: project.maySeeReports),
      _button(HomeScreen.suppliersKey(id), Icons.storefront_outlined, words.suppliersTitle, SuppliersScreen.pathOf(id)),
      _button(HomeScreen.accountsKey(id), Icons.account_balance_wallet_outlined, words.accountsTitle, AccountsScreen.pathOf(id)),
      _button(HomeScreen.partnersKey(id), Icons.handshake_outlined, words.partnersTitle, PartnersScreen.pathOf(id)),
      // Grayed until the next release works on it (Muteb, 12 Nov 2026); VatStatementScreen and its route stay as they are.
      _button(HomeScreen.vatKey(id), Icons.receipt_long_outlined, words.vatTitle, '', mayOpen: project.maySeeReports),
      if (project.may(Permission.approveEntries)) _button(HomeScreen.approvalsKey(id), Icons.fact_check_outlined, words.approvalsTitle, ApprovalsScreen.pathOf(id)),
      _button(HomeScreen.documentsKey(id), Icons.folder_outlined, words.documentsTitle, DocumentsScreen.pathOf(id)),
      _button(HomeScreen.projectInfoKey(id), Icons.info_outline, words.projectInfoTitle, ProjectInfoScreen.pathOf(id)),
      if (project.may(Permission.seeProjectHistory)) _button(HomeScreen.projectHistoryKey(id), Icons.history, words.historyProjectTitle, ProjectHistoryScreen.pathOf(id)),
      _button(HomeScreen.myPermissionsKey(id), Icons.verified_user_outlined, words.permissionsMine, MyPermissionsScreen.pathOf(id)),
      if (project.may(Permission.manageUsers)) _button(HomeScreen.usersKey(id), Icons.group_outlined, words.usersTitle, UsersScreen.pathOf(id)),
      if (project.may(Permission.manageUsers))
        _button(HomeScreen.permissionRequestsKey(id), Icons.how_to_reg_outlined, words.permissionRequestsListTitle, PermissionRequestsScreen.pathOf(id)),
      if (project.may(Permission.manageStructure)) _button(HomeScreen.categoriesKey(id), Icons.category_outlined, words.categoriesTitle, CategoriesScreen.pathOf(id)),
      if (project.may(Permission.manageSettings)) _button(HomeScreen.paymentMethodsKey(id), Icons.credit_card_outlined, words.paymentMethodsTitle, PaymentMethodsScreen.pathOf(id)),
      if (project.mayHandFiles) _doing(HomeScreen.loadFileKey(id), Icons.file_upload_outlined, words.projectsLoadFile, project.mayLoadFile ? widget.onLoadFile : null),
      if (project.mayHandFiles) _doing(HomeScreen.archiveKey(id), Icons.archive_outlined, words.projectsArchive, widget.onArchive),
      if (project.mayHandFiles) _doing(HomeScreen.retrieveKey(id), Icons.unarchive_outlined, words.projectsRetrieve, project.mayRetrieve ? widget.onRetrieve : null),
    ];
    final pages = [for (var start = 0; start < buttons.length; start += ProjectSettingsCard.perPage) buttons.skip(start).take(ProjectSettingsCard.perPage).toList()];
    return Card.outlined(
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
          SizedBox(
            height: _rowHeight(context) * 2,
            child: PageView.builder(
              key: HomeScreen.settingsPagesKey(id),
              controller: _pages,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _twoByTwo(pages[index % pages.length])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                for (var index = 0; index < pages.length; index++)
                  AnimatedContainer(
                    key: HomeScreen.settingsDotKey(id, index),
                    duration: kThemeAnimationDuration,
                    width: index == _page % pages.length ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(color: (index == _page % pages.length ? AppColor.brand : AppColor.frame).of(context), borderRadius: BorderRadius.circular(3)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
