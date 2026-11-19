// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Title and role name (UC-010)', () {
    phoneCase('the title names the open project', ($) async {
      final manager = await Given.manager(project: 'مشروع B', manager: 'ريم');
      await $.onTheHome(manager);
      await $.says(HomeScreen.titleKey, 'مشروع B');
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
