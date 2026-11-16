import 'package:flutter_test/flutter_test.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/documents/documents_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('A finished project is read-only (AC-04.1)', () {
    phoneCase('R13: its home says in one line that it is finished and read-only', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.says(HomeScreen.finishedKey(manager.projectId).title, '${$.words.projectsFinished} · ${$.words.projectsReadOnly}');
    });

    phoneCase('Users stays open on a finished project', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.usersKey(manager.projectId));
      await $.idOf('users.name.', () async => manager.id);
    });

    phoneCase('its reports stay available', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.reportsKey(manager.projectId));
      await $.reach($(ReportsScreen.noneIssuedKey));
    });

    phoneCase('More info offers no Add unit and no Close', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onMoreInfo(manager);
      await $.reach($(ProjectInfoScreen.descriptionTextKey));
      expect($(ProjectInfoScreen.addUnitKey), findsNothing);
      expect($(ProjectInfoScreen.closeKey), findsNothing);
    });

    phoneCase('categories, items and tables offer nothing to change', ($) async {
      final manager = await Given.manager();
      final bone = await Given.aCategoryAndItem(manager);
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.categoriesKey(manager.projectId));
      await $.reach($(CategoriesScreen.categoryTileKey(bone.categoryId)));
      expect($.isEnabled(CategoriesScreen.addCategoryKey), isFalse);
      expect($(CategoriesScreen.categoryHandleKey(bone.categoryId)), findsNothing);
      await $(CategoriesScreen.categoryTileKey(bone.categoryId)).tap();
      await $.reach($(CategoriesScreen.itemNameKey(bone.itemId)));
      expect($(CategoriesScreen.addItemKey(bone.categoryId)), findsNothing);
      expect($(CategoriesScreen.itemHandleKey(bone.itemId)), findsNothing);
      expect($(CategoriesScreen.itemMenuKey(bone.itemId)), findsNothing);
    });

    phoneCase('item columns offer nothing to change', ($) async {
      final manager = await Given.manager();
      final bone = await Given.aCategoryAndItem(manager);
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.categoriesKey(manager.projectId));
      await $.reach($(CategoriesScreen.categoryTileKey(bone.categoryId)));
      await $(CategoriesScreen.categoryTileKey(bone.categoryId)).tap();
      await $.tapOn(CategoriesScreen.itemColumnsKey(bone.itemId));
      await $.reach($(ItemColumnsScreen.addKey));
      expect($.isEnabled(ItemColumnsScreen.addKey), isFalse);
      expect($(keyedBy(ItemColumnsScreen.handleKey)), findsNothing);
      expect($(keyedBy(ItemColumnsScreen.menuKey)), findsNothing);
    });

    phoneCase('payment methods offer nothing to change', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.paymentMethodsKey(manager.projectId));
      await $.reach($(PaymentMethodsScreen.addKey));
      expect($.isEnabled(PaymentMethodsScreen.addKey), isFalse);
      expect($(keyedBy(PaymentMethodsScreen.menuKey)), findsNothing);
    });

    phoneCase('accounts offer nothing to change', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.accountsKey(manager.projectId));
      await $.reach($(AccountsScreen.nameKey(account)));
      expect($.isEnabled(AccountsScreen.addKey), isFalse);
      expect($(AccountsScreen.menuKey(account)), findsNothing);
    });

    phoneCase('partners offer nothing to change', ($) async {
      final manager = await Given.manager(partners: ['متعب']);
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.partnersKey(manager.projectId));
      await $.idOf('partners.name.', () => Given.partnerNamed(manager, 'متعب'));
      expect($.isEnabled(PartnersScreen.addKey), isFalse);
      expect($(keyedBy(PartnersScreen.menuKey)), findsNothing);
    });

    phoneCase('suppliers offer nothing to change', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.suppliersKey(manager.projectId));
      await $.reach($(SuppliersScreen.addKey));
      expect($.isEnabled(SuppliersScreen.addKey), isFalse);
      expect($(keyedBy(SuppliersScreen.menuKey)), findsNothing);
    });

    phoneCase('contracts offer nothing to change: a contract\'s ⋮ holds its files alone (Muteb, 12 Nov 2026)', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.contractsKey(manager.projectId));
      await $.reach($(ContractsScreen.valueOfKey(contract.id)));
      expect($.isEnabled(ContractsScreen.addKey), isFalse);
      await $.tapOn(ContractsScreen.menuKey(contract.id));
      await $.reach($(ContractsScreen.fileKey(ReportFileKind.pdf)));
      expect($(ContractsScreen.editKey), findsNothing);
      expect($(ContractsScreen.disableKey), findsNothing);
    });

    phoneCase('documents offer no Add and no Remove', ($) async {
      final manager = await Given.manager();
      final document = await Given.document(manager);
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.documentsKey(manager.projectId));
      await $.reach($(DocumentsScreen.documentKey(document)));
      expect($.isEnabled(DocumentsScreen.addKey), isFalse);
      expect($(DocumentsScreen.documentKey(document).swipe), findsNothing);
      expect($(DocumentsScreen.documentKey(document).bar), findsNothing);
    });

    phoneCase('Add entry is gray', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.addEntryKey(manager.projectId)));
      expect($.isEnabled(HomeScreen.addEntryKey(manager.projectId)), isFalse);
    });

    phoneCase('an entry does not swipe', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, sent: false);
      await Given.closed(manager);
      await $.onTheHome(manager);
      await $.goTo($(EntriesScreen.rowKey(entry)));
      expect($(EntriesScreen.rowKey(entry)), findsOneWidget);
      expect($(EntriesScreen.rowKey(entry).swipe), findsNothing);
      expect($(EntriesScreen.rowKey(entry).bar), findsNothing);
    });
  });
}
