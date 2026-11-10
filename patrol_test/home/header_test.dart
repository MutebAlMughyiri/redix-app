import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Title and role name (UC-010)', () {
    phoneCase('the title names the open project', ($) async {
      final manager = await Given.manager(project: 'غصون 7', manager: 'ريم');
      await $.onTheHome(manager);
      await $.says(HomeScreen.titleKey, 'غصون 7');
      await $.picture('home');
    });

    phoneCase('the role name typed for me shows under the project name', ($) async {
      final member = await Given.member(await Given.manager(), roleName: 'مهندس موقع');
      await $.onTheHome(member);
      await $.says(HomeScreen.roleNameKey, 'مهندس موقع');
    });

    phoneCase('where no role name was typed, nothing shows', ($) async {
      final member = await Given.member(await Given.manager());
      await $.onTheHome(member);
      expect($(HomeScreen.roleNameKey), findsNothing);
    });
  });
}
