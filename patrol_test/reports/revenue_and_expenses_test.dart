import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/ui/search_scope.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/summary.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

/// Signs [person] in and opens المصروفات, or the [side] given (Muteb, 12 Nov 2026: two screens).
Future<void> onReports(PatrolIntegrationTester $, Person person, {SummarySide side = SummarySide.expenses}) async {
  await $.fromTheHome(person, HomeScreen.itemReportsKey(person.projectId, side));
  await $.reach($(SearchIcons.searchKey));
}

/// Opens the category [name] and answers its id.
Future<String> openCategory(PatrolIntegrationTester $, String name) async {
  final id = await $.idShowing('itemReports.category.', name);
  await $.tapOn(ItemReportsScreen.categoryKey(id));
  await $.pumpAndSettle();
  return id;
}

void main() {
  phoneClass('الإيرادات والمصروفات (UC-049 and UC-053)', () {
    phoneCase('Muteb, 12 Nov 2026: المصروفات and الإيرادات are two buttons, each opening its own side with no switch', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await Given.entriesApproved(manager, [await Given.entry(manager, accountId: account), await Given.revenue(manager, accountId: account)]);
      final table = await Given.firstPurchaseTable(manager);
      await onReports($, manager);
      await $.idShowing('itemReports.category.', table.category);
      expect(find.text('استرجاع ضرائب'), findsNothing);
      await $.back();
      await $.tapOn(HomeScreen.itemReportsKey(manager.projectId, SummarySide.revenue));
      await $.idShowing('itemReports.category.', 'استرجاع ضرائب');
      expect(find.text(table.category), findsNothing);
    });

    phoneCase('a category opens to its items with their totals, and an item opens its report', ($) async {
      final manager = await Given.manager();
      await Given.entriesApproved(manager, [await Given.entry(manager, amount: 150)]);
      final table = await Given.firstPurchaseTable(manager);
      await onReports($, manager);
      await openCategory($, table.category);
      await $.says(ItemReportsScreen.itemKey(table.itemId).trailing, '150.00');
      await $.tapOn(ItemReportsScreen.itemKey(table.itemId));
      await $.says(ItemReportScreen.totalKey, '150.00');
    });

    phoneCase('AC-30.1: an item report shows its total, a table per subgroup, and each contract with what remains', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      final subgroup = await Given.subgroup(manager, contract.itemId, 'الجلاي');
      final account = await Given.account(manager);
      await Given.entriesApproved(manager, [await Given.entry(manager, amount: 50, accountId: account, itemId: contract.itemId, tableId: subgroup), await Given.contractorPayment(manager, contract, amount: 400, accountId: account)]);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.itemReportsKey(manager.projectId, SummarySide.expenses));
      final categories = await Given.categoryOf(manager, contract.itemId);
      await openCategory($, categories);
      await $.tapOn(ItemReportsScreen.itemKey(contract.itemId));
      await $.reach($(ItemReportScreen.subgroupKey(subgroup)));
      await $.goTo($(ItemReportScreen.contractCardKey(contract.id)));
      await $.says(ItemReportScreen.contractorKey(contract.id), contract.contractor);
    });

    phoneCase('redix-api #109: رأس المال opens to its item, and its report holds a table per partner', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      await Given.entriesApproved(manager, [await Given.partnerMoney(manager, partner, amount: 500)]);
      await onReports($, manager, side: SummarySide.revenue);
      await openCategory($, 'رأس المال');
      final item = await $.idShowing('itemReports.item.', 'رأس المال');
      await $.tapOn(ItemReportsScreen.itemKey(item));
      await $.reach($(ItemReportScreen.subgroupKey(partner)));
    });

    phoneCase('AC-33.1: an item report hands on its PDF', ($) async {
      final manager = await Given.manager();
      await Given.entriesApproved(manager, [await Given.entry(manager)]);
      final table = await Given.firstPurchaseTable(manager);
      await onReports($, manager);
      await openCategory($, table.category);
      await $.tapOn(ItemReportsScreen.itemKey(table.itemId));
      await $.goTo($(ReportFileButtons.buttonKey(table.itemName, ReportFileKind.pdf)));
      await $.tapOn(ReportFileButtons.buttonKey(table.itemName, ReportFileKind.pdf));
      await $.tapToThePhone(ReportFileButtons.handingKey(table.itemName, ReportFileKind.pdf, FileHandling.share));
      await $.shareSheetOffers('.pdf');
    });

    phoneCase('redix-api #131: without «يُصدر التقارير» an item report\'s PDF and Excel show gray', ($) async {
      final manager = await Given.manager();
      await Given.entriesApproved(manager, [await Given.entry(manager)]);
      final table = await Given.firstPurchaseTable(manager);
      final member = await Given.member(manager, permissions: [Permission.seeReports, Permission.seeAllCapital]);
      await onReports($, member);
      await openCategory($, table.category);
      await $.tapOn(ItemReportsScreen.itemKey(table.itemId));
      await $.goTo($(ReportFileButtons.buttonKey(table.itemName, ReportFileKind.pdf)));
      expect($.isEnabled(ReportFileButtons.buttonKey(table.itemName, ReportFileKind.pdf)), isFalse);
      expect($.isEnabled(ReportFileButtons.buttonKey(table.itemName, ReportFileKind.excel)), isFalse);
    });

    phoneCase('AC-30.1: a waiting entry is not in the report', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      final table = await Given.firstPurchaseTable(manager);
      await onReports($, manager);
      await $.pumpAndSettle();
      expect(find.text(table.itemName), findsNothing);
    });

    phoneCase('BR-31, redix-api #106: with a chosen partner someone sees only that partner\'s table',($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.seeReports]);
      final own = await Given.partner(manager, 'نواف');
      final other = await Given.partner(manager, 'هيثم');
      await Given.choosePartner(manager, member, own);
      await Given.entriesApproved(manager, [await Given.partnerMoney(manager, own), await Given.partnerMoney(manager, other)]);
      await onReports($, member, side: SummarySide.revenue);
      await openCategory($, 'رأس المال');
      final item = await $.idShowing('itemReports.item.', 'رأس المال');
      await $.tapOn(ItemReportsScreen.itemKey(item));
      await $.reach($(ItemReportScreen.subgroupKey(own)));
      expect($(ItemReportScreen.subgroupKey(other)), findsNothing);
    });
  });
}
