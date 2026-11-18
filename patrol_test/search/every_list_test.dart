// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/documents/documents_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/movements_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/ui/search_line.dart';
import 'package:redix/ui/search_scope.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// redix-app #104, version 3: every list opens on its rows with its search hidden; the title bar's search icon shows the search line, the same icon hides it again, and what
/// is typed keeps the rows that hold it, an Arabic word read alike whichever way it is spelled. The lists searched elsewhere: Entries (entries_list_test), Suppliers
/// (suppliers_test), the accounts' history (transfers_history_test), what waits (approve_entries_test) and صلاحياتي (my_permissions_test).
void main() {
  phoneClass('Search on every list (redix-app #104)', () {
    phoneCase('Documents: the search icon shows the line and the same icon hides it again, every document back', ($) async {
      final manager = await Given.manager();
      final permit = await Given.document(manager, name: 'رخصة البناء ${Given.unique()}');
      final plan = await Given.document(manager, name: 'مخطط الواجهة ${Given.unique()}');
      await $.fromTheHome(manager, HomeScreen.documentsKey(manager.projectId));
      await $.reach($(DocumentsScreen.documentKey(permit)));
      expect($(SearchLine.searchKey), findsNothing);
      await $.searchFor('رخصه');
      await $.gone($(DocumentsScreen.documentKey(plan)));
      await $.reach($(DocumentsScreen.documentKey(permit)));
      await $.tapOn(SearchIcons.searchKey);
      await $.gone($(SearchLine.searchKey));
      await $.goTo($(DocumentsScreen.documentKey(plan)));
    });

    phoneCase('Contracts: what is typed keeps the contracts of the contractor that holds it', ($) async {
      final manager = await Given.manager();
      final tiles = await Given.contract(manager, contractor: 'مقاول البلاط ${Given.unique()}');
      final steel = await Given.contract(manager, contractor: 'مقاول الحديد ${Given.unique()}');
      await $.fromTheHome(manager, HomeScreen.contractsKey(manager.projectId));
      await $.reach($(ContractsScreen.nameKey(steel.id)));
      await $.searchFor('البلاط');
      await $.gone($(ContractsScreen.nameKey(steel.id)));
      await $.reach($(ContractsScreen.nameKey(tiles.id)));
    });

    phoneCase('Users: what is typed keeps the people whose name holds it', ($) async {
      final manager = await Given.manager();
      final nawaf = await Given.member(manager, name: 'نواف ${Given.unique()}');
      final sara = await Given.member(manager, name: 'سارة ${Given.unique()}');
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.reach($(UsersScreen.rowKey(sara.id)));
      await $.searchFor('نواف');
      await $.gone($(UsersScreen.rowKey(sara.id)));
      await $.reach($(UsersScreen.rowKey(nawaf.id)));
    });

    phoneCase('A partner\'s movements: an amount typed keeps the movements of that amount', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'متعب');
      final small = await Given.partnerMoney(manager, partner, amount: 500);
      final large = await Given.partnerMoney(manager, partner, amount: 730);
      await Given.entriesApproved(manager, [small, large]);
      await $.fromTheHome(manager, HomeScreen.partnersKey(manager.projectId));
      await $.tapOn(PartnersScreen.rowKey(partner));
      await $.reach($(MovementsScreen.rowKey(small)));
      await $.searchFor('730');
      await $.gone($(MovementsScreen.rowKey(small)));
      await $.reach($(MovementsScreen.rowKey(large)));
    });

    phoneCase('a list searched for what nothing holds shows none of its rows, and closing the line shows them all again', ($) async {
      final manager = await Given.manager();
      final permit = await Given.document(manager, name: 'رخصة البناء ${Given.unique()}');
      await $.fromTheHome(manager, HomeScreen.documentsKey(manager.projectId));
      await $.reach($(DocumentsScreen.documentKey(permit)));
      await $.searchFor('لا شيء يحمل هذا');
      await $.gone($(DocumentsScreen.documentKey(permit)));
      await $.tapOn(SearchLine.closeKey);
      await $.goTo($(DocumentsScreen.documentKey(permit)));
    });
  });
}
