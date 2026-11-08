import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/documents/documents_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/home/dashboard_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/notifications/notifications_bell.dart';
import 'package:redix/notifications/notifications_screen.dart';
import 'package:redix/partners/movements_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/revenue/revenue_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';

import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// A step from the projects list towards where a control shows.
typedef Step = Future<void> Function(WidgetTester tester, FakeApi api, FakeCapture capture);

/// A control the app shows only to whoever holds [permission], reached by [steps] once [arrange] has filled the API.
typedef Gate = ({String name, Permission permission, void Function(FakeApi api) arrange, List<Step> steps, Finder Function(FakeApi api) control});

const _project = 'project-0';

/// Every permission there is: the admin's, and all a person can hold in a project.
const _every = [...admin, ...managerAndFinance];

Step _tap(Finder Function(FakeApi api) target) => (tester, api, capture) async {
  await tester.ensureVisible(target(api).last);
  await tester.pumpAndSettle();
  await act(tester, api, () => tester.tap(target(api).last));
};

Step _tapKey(Key key) => _tap((_) => find.byKey(key));

final _openProject = _tapKey(ProjectsScreen.cardKey(_project));

Future<void> _shareAPicture(WidgetTester tester, FakeApi api, FakeCapture capture) async {
  capture.share(PickedFile('receipt.png', '', Uint8List.fromList(onePixelPng)));
  await act(tester, api, () async {});
}

void _nothing(FakeApi api) {}

Finder Function(FakeApi api) _key(Key key) => (_) => find.byKey(key);

String _first(List<Map<String, Object>>? rows) => rows!.first['id']! as String;

final _dashboardWithAnItem = <String, Object>{
  ...FakeApi().dashboardAnswer,
  'categories': [
    {
      'id': 'category-1',
      'name': 'التشطيب',
      'total': 3000,
      'items': [
        {'id': 'item-1', 'name': 'البلاط', 'total': 3000},
      ],
    },
  ],
};

final List<Gate> _gates = [
  (name: 'Registered projects in the settings', permission: Permission.approveProjects, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project))], control: _key(SettingsScreen.registeredKey)),
  (name: 'Users in the settings', permission: Permission.manageUsers, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project))], control: _key(SettingsScreen.usersKey)),
  (name: 'Add unit in More info', permission: Permission.manageProject, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project)), _tapKey(SettingsScreen.projectInfoKey)], control: _key(ProjectInfoScreen.addUnitKey)),
  (name: 'Rename project in More info', permission: Permission.manageProject, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project)), _tapKey(SettingsScreen.projectInfoKey)], control: _key(ProjectInfoScreen.renameKey)),
  (name: 'Close project in More info', permission: Permission.manageProject, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project)), _tapKey(SettingsScreen.projectInfoKey)], control: _key(ProjectInfoScreen.closeKey)),
  (name: 'A unit\'s menu in More info', permission: Permission.manageProject, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project)), _tapKey(SettingsScreen.projectInfoKey)], control: _key(ProjectInfoScreen.unitMenuKey('$_project-unit-0'))),
  (name: 'The description in More info', permission: Permission.manageProject, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project)), _tapKey(SettingsScreen.projectInfoKey)], control: _key(ProjectInfoScreen.saveDescriptionKey)),
  (
    name: 'Add a document',
    permission: Permission.manageProject,
    arrange: _nothing,
    steps: [_openProject, _tapKey(HomeScreen.documentsKey(_project))],
    control: _key(DocumentsScreen.addKey),
  ),
  (
    name: 'Remove a document',
    permission: Permission.manageProject,
    arrange: (api) => api.documentRows.add({
      'id': 'permit',
      'name': 'رخصة البناء',
      'group': 'التراخيص',
      'attachmentId': 'attachment-permit',
      'fileName': 'permit.pdf',
      'contentType': 'application/pdf',
      'sizeBytes': 4,
      'uploadedAt': '2026-11-07T20:00:00Z',
    }),
    steps: [_openProject, _tapKey(HomeScreen.documentsKey(_project))],
    control: _key(DocumentsScreen.documentKey('permit').swipe),
  ),
  (name: 'Categories and items in the settings', permission: Permission.manageStructure, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project))], control: _key(SettingsScreen.categoriesKey)),
  (name: 'Payment methods in the settings', permission: Permission.manageSettings, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.settingsKey(_project))], control: _key(SettingsScreen.paymentMethodsKey)),
  (name: 'Add an account', permission: Permission.manageSettings, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.accountsKey(_project))], control: _key(AccountsScreen.addKey)),
  (
    name: 'An account\'s menu',
    permission: Permission.manageSettings,
    arrange: (api) => api.addAccount(_project, 'حساب المؤسسة'),
    steps: [_openProject, _tapKey(HomeScreen.accountsKey(_project))],
    control: (api) => find.byKey(AccountsScreen.menuKey(_first(api.accounts[_project]))),
  ),
  (name: 'Add a partner', permission: Permission.manageSettings, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.partnersKey(_project))], control: _key(PartnersScreen.addKey)),
  (
    name: 'Edit a partner',
    permission: Permission.manageSettings,
    arrange: (api) => api.addPartner(_project, 'متعب'),
    steps: [_openProject, _tapKey(HomeScreen.partnersKey(_project))],
    control: (api) => find.byKey(PartnersScreen.editKey(_first(api.partners[_project]))),
  ),
  (name: 'Add a supplier', permission: Permission.manageSettings, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.suppliersKey(_project))], control: _key(SuppliersScreen.addKey)),
  (
    name: 'A supplier\'s menu',
    permission: Permission.manageSettings,
    arrange: (api) => api.addSupplier(_project, 'شركة البواني للتجارة'),
    steps: [_openProject, _tapKey(HomeScreen.suppliersKey(_project))],
    control: (api) => find.byKey(SuppliersScreen.menuKey(_first(api.suppliers[_project]))),
  ),
  (name: 'Add a contract', permission: Permission.manageSettings, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.contractsKey(_project))], control: _key(ContractsScreen.addKey)),
  (
    name: 'A contract\'s menu',
    permission: Permission.manageSettings,
    arrange: (api) => api.addContract(_project, 'مؤسسة البلاط', value: 40000),
    steps: [_openProject, _tapKey(HomeScreen.contractsKey(_project))],
    control: (api) => find.byKey(ContractsScreen.menuKey(_first(api.contracts[_project]))),
  ),
  (
    name: 'Quick add in the supplier picker',
    permission: Permission.addSupplier,
    arrange: _nothing,
    steps: [_openProject, _tapKey(HomeScreen.addEntryKey(_project)), _tapKey(AddEntryScreen.supplierKey)],
    control: _key(SupplierPicker.quickAddKey),
  ),
  (name: 'إضافة قيد on the home', permission: Permission.recordEntries, arrange: _nothing, steps: [_openProject], control: _key(HomeScreen.addEntryKey(_project))),
  (
    name: 'Edit on one\'s own draft',
    permission: Permission.recordEntries,
    arrange: (api) => api.addEntry(status: 'draft'),
    steps: [_openProject, _tapKey(HomeScreen.entriesKey(_project)), _tapKey(EntriesScreen.rowKey('entry-0'))],
    control: _key(EntriesScreen.editKey),
  ),
  (
    name: 'The swipe that deletes one\'s own draft',
    permission: Permission.deleteEntries,
    arrange: (api) => api.addEntry(status: 'draft'),
    steps: [_openProject, _tapKey(HomeScreen.entriesKey(_project))],
    control: _key(EntriesScreen.rowKey('entry-0').swipe),
  ),
  (
    name: 'The camera in إضافة قيد',
    permission: Permission.attachFiles,
    arrange: _nothing,
    steps: [_openProject, _tapKey(HomeScreen.addEntryKey(_project))],
    control: _key(AddEntryScreen.cameraKey),
  ),
  (
    name: 'A contract\'s Add document',
    permission: Permission.attachFiles,
    arrange: _nothing,
    steps: [_openProject, _tapKey(HomeScreen.contractsKey(_project)), _tapKey(ContractsScreen.addKey)],
    control: _key(ContractsScreen.addDocumentKey),
  ),
  (name: 'A shared file as a new expense', permission: Permission.attachFiles, arrange: _nothing, steps: [_shareAPicture], control: _key(ShareScreen.newExpenseKey)),
  (
    name: 'Edit on someone else\'s entry',
    permission: Permission.manageAnyEntry,
    arrange: (api) => api.addEntry(isMine: false),
    steps: [_openProject, _tapKey(HomeScreen.entriesKey(_project)), _tapKey(EntriesScreen.allKey), _tapKey(EntriesScreen.rowKey('entry-0'))],
    control: _key(EntriesScreen.editKey),
  ),
  (
    name: 'The contracts report\'s files',
    permission: Permission.seeAllCapital,
    arrange: _nothing,
    steps: [_openProject, _tapKey(HomeScreen.reportsKey(_project))],
    control: _key(ReportFileButtons.buttonKey('contracts', ReportFileKind.pdf)),
  ),
  (
    name: 'A periodic report\'s files',
    permission: Permission.seeAllCapital,
    arrange: (api) => api
      ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
      ..periodicAnswer = issuedReport(),
    steps: [_openProject, _tapKey(HomeScreen.reportsKey(_project)), _tapKey(ReportsScreen.periodicKey(1))],
    control: _key(ReportFileButtons.buttonKey('report-1', ReportFileKind.pdf)),
  ),
  (
    name: 'The VAT statement\'s files',
    permission: Permission.seeAllCapital,
    arrange: _nothing,
    steps: [_openProject, _tapKey(HomeScreen.reportsKey(_project)), _tapKey(ReportsScreen.vatKey)],
    control: (_) => find.byType(ReportFileButtons),
  ),
  (
    name: 'An item report\'s files',
    permission: Permission.seeAllCapital,
    arrange: (api) => api.dashboardAnswer = _dashboardWithAnItem,
    steps: [_openProject, _tapKey(DashboardCard.expensesKey), _tapKey(DashboardCard.categoryKey('category-1')), _tapKey(DashboardCard.itemKey('item-1'))],
    control: (_) => find.byType(ReportFileButtons),
  ),
  (name: 'Approvals on the project card', permission: Permission.approveEntries, arrange: _nothing, steps: [_openProject], control: _key(HomeScreen.approvalsKey(_project))),
  (
    name: 'Approve, reached from a notification',
    permission: Permission.approveEntries,
    arrange: (api) => api
      ..addPending()
      ..addNotification(),
    steps: [_openProject, _tapKey(NotificationsBell.buttonKey), _tapKey(NotificationsScreen.rowKey('notification-0'))],
    control: _key(ApprovalsScreen.approveKey('entry-0')),
  ),
  (
    name: 'What waits on the dashboard',
    permission: Permission.approveEntries,
    arrange: (api) => api.dashboardAnswer = {...api.dashboardAnswer, 'pendingCount': 2, 'pendingAmount': 200},
    steps: [_openProject],
    control: _key(DashboardCard.pendingKey),
  ),
  (
    name: 'Reverse an approved entry',
    permission: Permission.approveEntries,
    arrange: (api) => api.addEntry(status: 'approved'),
    steps: [_openProject, _tapKey(HomeScreen.entriesKey(_project)), _tapKey(EntriesScreen.rowKey('entry-0'))],
    control: _key(EntriesScreen.reverseKey),
  ),
  (
    name: 'Reverse a capital movement',
    permission: Permission.approveEntries,
    arrange: (api) => api
      ..addPartner(_project, 'متعب')
      ..addMovement(),
    steps: [_openProject, _tapKey(HomeScreen.partnersKey(_project)), _tap((_) => find.text('متعب'))],
    control: _key(MovementsScreen.reverseKey('movement-0')),
  ),
  (
    name: 'Reverse revenue',
    permission: Permission.approveEntries,
    arrange: (api) => api.addRevenue(),
    steps: [_openProject, _tapKey(HomeScreen.revenueKey(_project))],
    control: _key(RevenueScreen.reverseKey('revenue-0')),
  ),
  (
    name: 'Reconcile on the accounts',
    permission: Permission.moveMoney,
    arrange: (api) => api.addAccount(_project, 'البنك'),
    steps: [_openProject, _tapKey(HomeScreen.accountsKey(_project))],
    control: _key(AccountsScreen.reconcileKey),
  ),
  (name: 'Issue a periodic report', permission: Permission.moveMoney, arrange: _nothing, steps: [_openProject, _tapKey(HomeScreen.reportsKey(_project))], control: _key(ReportsScreen.issueKey)),
  (
    name: 'A partner in Add entry\'s table list',
    permission: Permission.moveMoney,
    arrange: (api) => api.addPartner(_project, 'متعب'),
    steps: [_openProject, _tapKey(HomeScreen.addEntryKey(_project)), _tapKey(AddEntryScreen.tableKey)],
    control: (api) => find.byKey(TablePicker.optionKey(api.partners[_project]!.single['id']! as String)),
  ),
  (
    name: 'A revenue item in Add entry\'s table list',
    permission: Permission.moveMoney,
    arrange: (api) => api.addItem(api.addCategory(_project, 'الإيرادات'), 'إيرادات أخرى', type: 'otherRevenue'),
    steps: [_openProject, _tapKey(HomeScreen.addEntryKey(_project)), _tapKey(AddEntryScreen.tableKey)],
    control: (api) => find.byKey(TablePicker.categoryKey('الإيرادات')),
  ),
];

void main() {
  Future<FakeApi> open(WidgetTester tester, Gate gate, List<String> permissions) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()
      ..permissions = permissions
      ..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    gate.arrange(api);
    final capture = FakeCapture();
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    for (final step in gate.steps) {
      await step(tester, api, capture);
    }
    return api;
  }

  test('findings row 134: every permission that hides a control has one here; readProject is membership itself, and chargeAnyAccount only widens the accounts offered', () {
    expect({for (final gate in _gates) gate.permission}, Permission.values.toSet().difference({Permission.readProject, Permission.chargeAnyAccount}));
  });

  for (final gate in _gates) {
    testWidgets('FR-03: ${gate.name} shows to whoever holds ${gate.permission.name}', (tester) async {
      final api = await open(tester, gate, _every);

      expect(gate.control(api), findsWidgets);
    });

    testWidgets('FR-03: ${gate.name} is not shown without ${gate.permission.name}', (tester) async {
      final api = await open(tester, gate, [for (final permission in _every) if (permission != gate.permission.name) permission]);

      expect(gate.control(api), findsNothing);
    });
  }
}
