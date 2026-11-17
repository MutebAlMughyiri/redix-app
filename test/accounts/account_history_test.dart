import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/account_history.dart';
import 'package:redix/words/words.dart';

import '../app_harness.dart';

void main() {
  final words = Words({'history.custodianChanged': '{0} is now held by {1}', 'accounts.noCustodian': 'nobody'});

  AccountHistoryLine custodianLine(String custodian) => AccountHistoryLine.fromJson(FakeApi().addHistoryLine('project-0', 'custodianChanged', account: 'كاش مع نواف', custodian: custodian));

  test('redix-app #89: a custodian line names the account and who holds it now', () {
    expect(custodianLine('نواف').textIn(words), 'كاش مع نواف is now held by نواف');
  });

  test('redix-app #89: a custodian line whose account nobody holds now says so', () {
    expect(custodianLine('').textIn(words), 'كاش مع نواف is now held by nobody');
  });
}
