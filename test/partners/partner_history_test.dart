import 'package:flutter_test/flutter_test.dart';
import 'package:redix/partners/partner_history.dart';
import 'package:redix/words/words.dart';

import '../app_harness.dart';

void main() {
  final words = Words({
    'history.partnerChanged': 'renamed {0}{1}',
    'history.nameWas': ', was {0}',
    'history.partnerAccount': '{0} signs in as {1}',
    'partners.noLogin': 'no login',
  });

  PartnerHistoryLine lineOf(String kind, {String nameWas = '', String login = ''}) =>
      PartnerHistoryLine.fromJson(FakeApi().addPartnerHistoryLine('project-0', kind, partner: 'متعب', nameWas: nameWas, login: login));

  test('redix-app #101: a renamed partner\'s line names the partner and the name they had', () {
    expect(lineOf('partnerChanged', nameWas: 'متعب المغيري').textIn(words), 'renamed متعب, was متعب المغيري');
  });

  test('redix-app #101: a partner\'s line with no earlier name says only who', () {
    expect(lineOf('partnerChanged').textIn(words), 'renamed متعب');
  });

  test('redix-app #101: a partner given a login names it, and one left with none says so', () {
    expect(lineOf('partnerAccount', login: 'mutab').textIn(words), 'متعب signs in as mutab');
    expect(lineOf('partnerAccount').textIn(words), 'متعب signs in as no login');
  });
}
