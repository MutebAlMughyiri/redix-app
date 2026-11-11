import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/documents/documents_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/structure/item_tables_screen.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/bottom_button.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

const _project = 'project-0';

/// Every permission there is.
const _every = [...admin, ...managerAndFinance];

/// A screen's main action (issue #85): reached by [reach] once [arrange] has filled the API, keyed [key], showing [icon].
typedef MainAction = ({String name, void Function(FakeApi api) arrange, List<Key> reach, Key key, IconData icon});

void _nothing(FakeApi api) {}

final _card = ProjectsScreen.cardKey(_project);

/// The category and item the fake API numbers first.
void _anItem(FakeApi api) => api.addItem(api.addCategory(_project, 'التشطيب'), 'البلاط');
final _theItemsCategory = [_card, HomeScreen.categoriesKey(_project), CategoriesScreen.categoryTileKey('category-0')];

final List<MainAction> _mainActions = [
  (name: 'Home: إضافة قيد', arrange: _nothing, reach: [_card], key: HomeScreen.addEntryKey(_project), icon: Icons.add),
  (name: 'Suppliers', arrange: _nothing, reach: [_card, HomeScreen.suppliersKey(_project)], key: SuppliersScreen.addKey, icon: Icons.add),
  (name: 'Contracts', arrange: _nothing, reach: [_card, HomeScreen.contractsKey(_project)], key: ContractsScreen.addKey, icon: Icons.add),
  (name: 'Categories', arrange: _nothing, reach: [_card, HomeScreen.categoriesKey(_project)], key: CategoriesScreen.addCategoryKey, icon: Icons.add),
  (
    name: 'An item\'s tables',
    arrange: _anItem,
    reach: [..._theItemsCategory, CategoriesScreen.itemMenuKey('item-1'), CategoriesScreen.tablesKey],
    key: ItemTablesScreen.addKey,
    icon: Icons.add,
  ),
  (
    name: 'An item\'s columns',
    arrange: _anItem,
    reach: [..._theItemsCategory, CategoriesScreen.itemColumnsKey('item-1')],
    key: ItemColumnsScreen.addKey,
    icon: Icons.add,
  ),
  (name: 'Projects', arrange: _nothing, reach: [], key: ProjectsScreen.newProjectKey, icon: Icons.add),
  (name: 'Share: a new entry with the file', arrange: _nothing, reach: [], key: ShareScreen.newExpenseKey, icon: Icons.add),
  (
    name: 'Approvals: approve selected',
    arrange: (api) => api.addPending(),
    reach: [_card, HomeScreen.approvalsKey(_project), ApprovalsScreen.selectKey('entry-0')],
    key: ApprovalsScreen.approveSelectedKey,
    icon: Icons.done_all,
  ),
];

/// The screens whose add is a + in the title bar, as the actions used less (redix-app #106): each with the word its tooltip says and the permission it grays without, if
/// the screen opens at all without it.
final List<(MainAction, String, Permission?)> _titleBarAdds = [
  ((name: 'Documents', arrange: _nothing, reach: [_card, HomeScreen.documentsKey(_project)], key: DocumentsScreen.addKey, icon: Icons.add), 'en documents.add', Permission.manageProject),
  ((name: 'Payment methods', arrange: _nothing, reach: [_card, HomeScreen.paymentMethodsKey(_project)], key: PaymentMethodsScreen.addKey, icon: Icons.add), 'en paymentMethods.new', null),
  ((name: 'Users', arrange: _nothing, reach: [_card, HomeScreen.usersKey(_project)], key: UsersScreen.newUserKey, icon: Icons.add), 'en users.new', null),
];

void main() {
  Future<FakeApi> open(WidgetTester tester, MainAction action, {List<String> permissions = _every}) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()
      ..permissions = permissions
      ..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    action.arrange(api);
    final capture = FakeCapture();
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    if (action.key == ShareScreen.newExpenseKey) {
      capture.share(PickedFile('receipt.png', '', Uint8List.fromList(onePixelPng)));
      await act(tester, api, () async {});
    }
    for (final step in action.reach) {
      await showProjectSetting(tester, step);
      await bringIntoView(tester, find.byKey(step));
      await act(tester, api, () => tester.tap(find.byKey(step)));
    }
    return api;
  }

  for (final action in _mainActions) {
    testWidgets('#85: ${action.name} is the one bottom button, full width, as إضافة قيد is', (tester) async {
      await open(tester, action);

      final button = find.descendant(of: find.byType(BottomButton), matching: find.byKey(action.key));
      expect(isEnabled(tester, action.key), isTrue);
      expect(tester.getSize(button).width, 900 - 16);
      expect(tester.widget<Icon>(find.byKey(action.key.icon)).icon, action.icon);
    });

    testWidgets('#85: ${action.name} has no floating button', (tester) async {
      await open(tester, action);

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  }

  for (final (key, permission) in [
    (HomeScreen.addEntryKey(_project), Permission.recordEntries),
    (SuppliersScreen.addKey, Permission.manageSettings),
    (ContractsScreen.addKey, Permission.manageSettings),
  ]) {
    final action = _mainActions.firstWhere((action) => action.key == key);
    testWidgets('#85: without ${permission.name}, ${action.name} shows grayed, never hidden', (tester) async {
      await open(tester, action, permissions: [for (final held in _every) if (held != permission.name) held]);

      expect(isEnabled(tester, action.key), isFalse);
    });
  }

  testWidgets('redix-app #89 D21: the one bottom bar of Accounts holds Transfer and Update side by side, each half its width', (tester) async {
    await open(tester, (
      name: 'Accounts',
      arrange: (api) => api
        ..addAccount(_project, 'البنك')
        ..addAccount(_project, 'كاش'),
      reach: [_card, HomeScreen.accountsKey(_project)],
      key: AccountsScreen.transferKey,
      icon: Icons.sync_alt,
    ));

    final bar = find.byType(BottomButton);
    expect(bar, findsOneWidget);
    for (final key in [AccountsScreen.transferKey, AccountsScreen.updateKey]) {
      expect(isEnabled(tester, key), isTrue);
      expect(tester.getSize(find.descendant(of: bar, matching: find.byKey(key))).width, (900 - 16 - 8) / 2);
    }
    expect(tester.widget<Icon>(find.byKey(AccountsScreen.transferKey.icon)).icon, Icons.sync_alt);
  });

  for (final (action, tooltip, permission) in _titleBarAdds) {
    testWidgets('redix-app #106 R1, R3: ${action.name} adds from a + in the title bar that says what it adds, and has no bottom button', (tester) async {
      await open(tester, action);

      expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(action.key)), findsOneWidget);
      expect(tester.widget<Icon>(find.byKey(action.key.icon)).icon, Icons.add);
      expect(tester.widget<IconButton>(find.byKey(action.key)).tooltip, tooltip);
      expect(isEnabled(tester, action.key), isTrue);
      expect(find.byType(BottomButton), findsNothing);
    });

    if (permission != null) {
      testWidgets('redix-app #106 R3: without ${permission.name}, the + of ${action.name} shows grayed, never hidden', (tester) async {
        await open(tester, action, permissions: [for (final held in _every) if (held != permission.name) held]);

        expect(isEnabled(tester, action.key), isFalse);
      });
    }
  }

  testWidgets('#85: a long list\'s last row scrolls fully above the button, which covers no row', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: _every, units: ['الفلة']);
    var last = '';
    for (var index = 0; index < 30; index++) {
      last = api.addSupplier(_project, 'مورد $index')['id']! as String;
    }
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.suppliersKey(_project));
    await tester.ensureVisible(projectSettingPages);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, api, HomeScreen.suppliersKey(_project));

    await tester.scrollUntilVisible(find.byKey(SuppliersScreen.rowKey(last)), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    final buttonTop = tester.getTopLeft(find.byType(BottomButton)).dy;
    expect(tester.getBottomLeft(find.byKey(SuppliersScreen.rowKey(last))).dy, lessThanOrEqualTo(buttonTop));
  });
}
