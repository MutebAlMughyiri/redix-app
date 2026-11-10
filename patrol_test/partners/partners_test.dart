import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Partners.
Future<void> onPartners(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.partnersKey(person.projectId));
  await $.reach($(PartnersScreen.addKey));
}

/// Opens the dialog of a new partner and types [name]; the project's capital item is not asked (redix-api #106).
Future<void> fillPartner(PatrolIntegrationTester $, String name) async {
  await $.tapOn(PartnersScreen.addKey);
  await $(PartnersScreen.partnerNameKey).enterText(name);
}

/// Chooses the partner's account [id] in the dialog showing now; empty for none.
Future<void> chooseLogin(PatrolIntegrationTester $, String id) => $.chooseMember(PartnersScreen.loginKey, id);

void main() {
  phoneClass('Partners (UC-016 and UC-040)', () {
    phoneCase('redix-api #106: a partner is added by name alone, joining the project\'s capital item', ($) async {
      final manager = await Given.manager();
      await onPartners($, manager);
      await fillPartner($, 'هيثم');
      await $(ChangeDialog.saveKey).tap();
      await $.idShowing('partners.name.', 'هيثم');
    });

    phoneCase('a partner is added with their account, chosen from the project\'s people', ($) async {
      final manager = await Given.manager(project: 'غصون 7', manager: 'مدير المشروع');
      await Given.partner(manager, 'هيثم');
      await onPartners($, manager);
      await fillPartner($, 'مدير المشروع');
      await chooseLogin($, manager.id);
      await $.picture('partner-dialog');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('partners.name.', 'مدير المشروع');
      await $.says(PartnersScreen.detailsKey(id), 'مدير المشروع');
      await $.picture('partners');
    });

    phoneCase('each partner shows their account, or that they have none', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, name: 'نواف');
      final withLogin = await Given.partner(manager, 'متعب', login: member);
      final without = await Given.partner(manager, 'هيثم');
      await onPartners($, manager);
      await $.says(PartnersScreen.detailsKey(withLogin), 'نواف');
      await $.says(PartnersScreen.detailsKey(without), $.words.partnersNoLogin);
    });

    phoneCase('adding with no account sends none', ($) async {
      final manager = await Given.manager();
      await onPartners($, manager);
      await fillPartner($, 'هيثم');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('partners.name.', 'هيثم');
      await $.says(PartnersScreen.detailsKey(id), $.words.partnersNoLogin);
    });

    phoneCase('editing starts from the partner and renames them', ($) async {
      final manager = await Given.manager();
      final id = await Given.partner(manager, 'هيثم');
      await onPartners($, manager);
      await $.tapOn(PartnersScreen.editKey(id));
      await $.reach($(PartnersScreen.partnerNameKey));
      expect($.typed(PartnersScreen.partnerNameKey), 'هيثم');
      await $(PartnersScreen.partnerNameKey).enterText('هيثم الأول');
      await $(ChangeDialog.saveKey).tap();
      await $.says(PartnersScreen.nameKey(id), 'هيثم الأول');
    });

    phoneCase('editing can give an account, and take it away', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, name: 'نواف');
      final id = await Given.partner(manager, 'هيثم');
      await onPartners($, manager);
      await $.tapOn(PartnersScreen.editKey(id));
      await chooseLogin($, member.id);
      await $(ChangeDialog.saveKey).tap();
      await $.says(PartnersScreen.detailsKey(id), 'نواف');
      await $.tapOn(PartnersScreen.editKey(id));
      await chooseLogin($, '');
      await $(ChangeDialog.saveKey).tap();
      await $.says(PartnersScreen.detailsKey(id), $.words.partnersNoLogin);
    });

    phoneCase('AC-27.1: each partner shows a balance and a share with ten decimals, under the total', ($) async {
      final manager = await Given.manager();
      final first = await Given.partner(manager, 'متعب');
      final second = await Given.partner(manager, 'هيثم');
      await Given.entriesApproved(manager, [await Given.partnerMoney(manager, first, amount: 2000), await Given.partnerMoney(manager, second, amount: 1000)]);
      await onPartners($, manager);
      await $.says(PartnersScreen.totalKey, '3,000.00');
      await $.says(PartnersScreen.balanceKey(first), '2,000.00');
      await $.says(PartnersScreen.shareKey(first), '66.6666666667%');
      expect($.topOf(PartnersScreen.totalKey), lessThan($.topOf(PartnersScreen.nameKey(first))));
    });

    phoneCase('BR-31: whoever holds seeAllCapital sees every partner', ($) async {
      final manager = await Given.manager();
      final first = await Given.partner(manager, 'متعب');
      final second = await Given.partner(manager, 'هيثم');
      final member = await Given.member(manager, permissions: [Permission.seeAllCapital]);
      await onPartners($, member);
      await $.reach($(PartnersScreen.nameKey(first)));
      await $.reach($(PartnersScreen.nameKey(second)));
    });

    phoneCase('BR-31, redix-api #106: a partner chosen for someone shows to them', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final chosen = await Given.partner(manager, 'نواف');
      await Given.choosePartner(manager, member, chosen);
      await onPartners($, member);
      await $.reach($(PartnersScreen.nameKey(chosen)));
    });

    phoneCase('redix-api #106: a partner\'s own account gives no sight: linked but not chosen, the partner does not show', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final own = await Given.partner(manager, 'نواف', login: member);
      await onPartners($, member);
      await $.says(ApiListBody.emptyKey, $.words.partnersEmpty);
      expect($(PartnersScreen.nameKey(own)), findsNothing);
    });

    phoneCase('pulling down reads the capital again', ($) async {
      final manager = await Given.manager();
      final id = await Given.partner(manager, 'متعب');
      await onPartners($, manager);
      await $.says(PartnersScreen.totalKey, '0.00');
      await Given.entriesApproved(manager, [await Given.partnerMoney(manager, id, amount: 500)]);
      await $.pullDown();
      await $.says(PartnersScreen.totalKey, '500.00');
    });

    phoneCase('BR-31, redix-api #106: with chosen partners someone sees only those, not the others', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final chosen = await Given.partner(manager, 'نواف');
      final other = await Given.partner(manager, 'متعب');
      await Given.choosePartner(manager, member, chosen);
      await onPartners($, member);
      await $.reach($(PartnersScreen.nameKey(chosen)));
      expect($(PartnersScreen.nameKey(other)), findsNothing);
    });

    phoneCase('seeing all capital without keeping the settings shows them with nothing to change', ($) async {
      final manager = await Given.manager();
      final id = await Given.partner(manager, 'متعب');
      final member = await Given.member(manager, permissions: [Permission.seeAllCapital]);
      await onPartners($, member);
      await $.reach($(PartnersScreen.nameKey(id)));
      expect($.isEnabled(PartnersScreen.addKey), isFalse);
      expect($(PartnersScreen.editKey(id)), findsNothing);
    });

    phoneCase('redix-api #101 R1: Partners has no حركة: a partner\'s money is entered from Add entry', ($) async {
      final manager = await Given.manager();
      final id = await Given.partner(manager, 'متعب');
      await onPartners($, manager);
      await $.reach($(PartnersScreen.nameKey(id)));
      expect($(keyStartingWith('partners.movement')), findsNothing);
      expect(find.text($.words.capitalContribution), findsNothing);
    });

    phoneCase('a project with no partners says so', ($) async {
      final manager = await Given.manager();
      await onPartners($, manager);
      await $.says(ApiListBody.emptyKey, $.words.partnersEmpty);
    });

    phoneCase('a refusal stays in the dialog', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await Given.partner(manager, 'متعب', login: member);
      await onPartners($, manager);
      await fillPartner($, 'هيثم');
      await chooseLogin($, member.id);
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.partnersUserTaken);
      expect($(PartnersScreen.partnerNameKey), findsOneWidget);
    });

    phoneCase('a list that cannot be read says so', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await Pc.cutNetwork();
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.partnersKey(manager.projectId));
      await $.says(ApiListBody.messageKey, $.words.partnersLoadFailed);
    });
  });
}
