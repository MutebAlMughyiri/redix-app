// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:redix/auth/permission.dart';
import 'package:uuid/uuid.dart';

/// Someone a case signs in as, and the project they are in.
class Person {
  /// [username] signs in with [password], and [id] is in the project [projectId] called [projectName].
  const Person({required this.id, required this.username, required this.password, required this.displayName, required this.projectId, required this.projectName});

  /// Nobody: what a case passes when no one else is meant.
  static const none = Person(id: '', username: '', password: '', displayName: '', projectId: '', projectName: '');

  /// Their user id, known for whoever a manager added.
  final String id;

  /// What they sign in with.
  final String username;

  /// Their password as it stands.
  final String password;

  /// What they are called.
  final String displayName;

  /// The one project they are in.
  final String projectId;

  /// What that project is called.
  final String projectName;

  /// The address of their project in the API.
  String get project => '/projects/$projectId';

  /// Whether this is nobody.
  bool get isNone => username.isEmpty;
}

/// A contract a case made.
typedef MadeContract = ({String id, String itemId, String supplierId, String contractor});

/// What a case finds already in place, made through the real API so that only what the case is about goes through the screens.
class Given {
  Given._();

  static const _base = String.fromEnvironment('API_BASE_URL');
  static const _adminUsername = String.fromEnvironment('TEST_USERNAME');
  static const _adminTemporaryPassword = String.fromEnvironment('TEST_PASSWORD');
  static const _adminPassword = String.fromEnvironment('TEST_NEW_PASSWORD');
  static var _made = 0;

  /// A short text no other case of this run has, since usernames must not repeat.
  static String unique() => '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${_made++}';

  /// A VAT number no other case of this run has: fifteen digits, starting and ending with 3.
  static String vatNumber() {
    final digits = '${DateTime.now().millisecondsSinceEpoch}${_made++}'.padLeft(13, '0');
    return '3${digits.substring(digits.length - 13)}3';
  }

  static String get _today => DateTime.now().toIso8601String().substring(0, 10);

  /// The admin, who approves projects.
  static Future<Person> admin() async {
    await _adminToken();
    return const Person(id: '', username: _adminUsername, password: _adminPassword, displayName: '', projectId: '', projectName: '');
  }

  /// The manager of a new project still waiting for the admin, signing in with a password of their own. Whatever is left empty is made up.
  static Future<Person> registered({String project = '', String manager = '', String mobile = '', String description = '', List<String> units = const [], List<String> partners = const [], String startDate = ''}) async {
    final mark = unique();
    final username = 'manager-$mark';
    final password = 'Chosen-$mark-2';
    final projectName = project.isEmpty ? 'Project $mark' : project;
    final displayName = manager.isEmpty ? 'Manager $mark' : manager;
    final made = await _post('/projects/register', {
      'name': projectName,
      'startDate': startDate.isEmpty ? _today : startDate,
      'units': units,
      'displayName': displayName,
      'username': username,
      'mobile': mobile,
      'password': password,
      'description': description,
      'partners': partners,
    });
    final session = await _signedIn(username, password);
    return Person(id: session['userId'] as String, username: username, password: password, displayName: displayName, projectId: made['id'] as String, projectName: projectName);
  }

  /// The manager of a new approved project, signing in with a password of their own.
  static Future<Person> manager({String project = '', String manager = '', String description = '', List<String> units = const [], List<String> partners = const [], String startDate = ''}) async {
    final person = await registered(project: project, manager: manager, description: description, units: units, partners: partners, startDate: startDate);
    await approved(person.projectId);
    return person;
  }

  /// A new person in the project of [manager], holding [permissions] beside seeing it, reached at an email of their username's (redix-api #127). With [temporary] they still
  /// hold the password they must change.
  static Future<Person> member(Person manager, {bool temporary = false, List<Permission> permissions = const [], String name = '', String mobile = '', String roleName = ''}) async {
    final mark = unique();
    final username = 'member-$mark';
    final displayName = name.isEmpty ? 'Member $mark' : name;
    final temporaryPassword = 'Temporary-$mark-1';
    final user = await _post('${manager.project}/users', {
      'displayName': displayName,
      'username': username,
      'mobile': mobile,
      'email': '$username@example.com',
      'temporaryPassword': temporaryPassword,
      'permissions': [for (final permission in permissions) permission.name],
      'roleName': roleName,
    }, await _tokenOf(manager));
    final id = user['id'] as String;
    if (temporary) {
      return Person(id: id, username: username, password: temporaryPassword, displayName: displayName, projectId: manager.projectId, projectName: manager.projectName);
    }
    final password = 'Chosen-$mark-2';
    final session = await _signedIn(username, temporaryPassword);
    await _post('/auth/change-password', {'currentPassword': temporaryPassword, 'newPassword': password}, session['accessToken'] as String);
    return Person(id: id, username: username, password: password, displayName: displayName, projectId: manager.projectId, projectName: manager.projectName);
  }

  /// [by] makes [person] inactive in [by]'s project, as «تعطيل» in Users does (redix-api #126 D1).
  static Future<void> disabled(Person person, {required Person by}) async {
    await _post('${by.project}/users/${person.id}/disable', {}, await _tokenOf(by));
  }

  /// What [person] may do in the project of [by], as the API lists it.
  static Future<List<String>> permissionsOf(Person by, String username) async {
    final users = await _getList('${by.project}/users', await _tokenOf(by));
    final user = users.cast<Map<String, dynamic>>().singleWhere((user) => user['username'] == username);
    final project = (user['projects'] as List<dynamic>).cast<Map<String, dynamic>>().singleWhere((project) => project['projectId'] == by.projectId);
    return (project['permissions'] as List<dynamic>).cast<String>();
  }

  /// [by] writes [roleName] for [person] in the project of [by].
  static Future<void> roleName(Person person, String roleName, {required Person by}) async {
    await _put('${by.project}/users/${person.id}/role-name', {'roleName': roleName}, await _tokenOf(by));
  }

  /// The admin approves the project [projectId].
  static Future<void> approved(String projectId) async {
    await _post('/projects/$projectId/approve', {}, await _adminToken());
  }

  /// The admin rejects the project [projectId], saying [reason].
  static Future<void> rejected(String projectId, String reason) async {
    await _post('/projects/$projectId/reject', {'reason': reason}, await _adminToken());
  }

  /// The admin decides everything waiting, so a case starts with an empty list.
  static Future<void> nothingWaiting() async {
    final token = await _adminToken();
    for (final waiting in await _getList('/projects/registered', token)) {
      await _post('/projects/${waiting['id']}/reject', {'reason': 'Cleared for a test'}, token);
    }
  }

  /// What the admin sees of the waiting project called [projectName].
  static Future<Map<String, dynamic>> waiting(String projectName) async {
    final all = await _getList('/projects/registered', await _adminToken());
    return all.cast<Map<String, dynamic>>().singleWhere((project) => project['name'] == projectName);
  }

  /// [person] starts another project, which waits for the admin, and its id is answered.
  static Future<String> started(Person person) async {
    final made = await _post('/projects', {'name': 'Started ${unique()}', 'startDate': _today, 'units': <String>[]}, await _tokenOf(person));
    return made['id'] as String;
  }

  /// [by] adds [person] to the project of [by].
  static Future<void> joined(Person person, {required Person by, List<Permission> permissions = const []}) async {
    final token = await _tokenOf(by);
    await _post('${by.project}/users/existing', {'username': person.username}, token);
    await ticked(person, permissions, by: by);
  }

  /// [by] ticks [permissions] for [person] in the project of [by]: a manager ticks for themselves a permission nobody holds until it is ticked, as removing approved entries (redix-api #119).
  static Future<void> ticked(Person person, List<Permission> permissions, {required Person by}) async {
    final token = await _tokenOf(by);
    for (final permission in permissions) {
      await _post('${by.project}/users/${person.id}/permissions/${permission.name}', {}, token);
    }
  }

  /// [by] takes [person] off the project.
  static Future<void> removed(Person person, {required Person by}) async {
    await _delete('${by.project}/users/${person.id}/permissions/readProject', await _tokenOf(by));
  }

  /// [person] makes their project the default.
  static Future<void> defaultProject(Person person) async {
    await _post('${person.project}/default', {}, await _tokenOf(person));
  }

  /// [manager] renames their project to [name].
  static Future<void> renamed(Person manager, String name) async {
    await _put(manager.project, {'name': name}, await _tokenOf(manager));
  }

  /// [manager] closes their project.
  static Future<void> closed(Person manager) async {
    await _post('${manager.project}/close', {}, await _tokenOf(manager));
  }

  /// [manager] adds the category [name], and its id is answered.
  static Future<String> category(Person manager, String name) async {
    final made = await _post('${manager.project}/categories', {'name': name}, await _tokenOf(manager));
    return made['id'] as String;
  }

  /// [manager] adds the item [name] of [type] to the category [categoryId], and its id is answered.
  static Future<String> item(Person manager, String categoryId, String name, {String type = 'both'}) async {
    final made = await _post('${manager.project}/categories/$categoryId/items', {'name': name, 'type': type}, await _tokenOf(manager));
    return made['id'] as String;
  }

  /// [manager] adds the sub-table [name] to the item [itemId], and its id is answered.
  static Future<String> subgroup(Person manager, String itemId, String name) async {
    final token = await _tokenOf(manager);
    await _post('${manager.project}/items/$itemId/subgroups', {'name': name}, token);
    final tables = await _getList('${manager.project}/items/$itemId/tables', token);
    return tables.cast<Map<String, dynamic>>().singleWhere((table) => table['name'] == name)['id'] as String;
  }

  /// [manager] adds a text column [name] to the item [itemId].
  static Future<void> column(Person manager, String itemId, String name, {bool required = false}) async {
    await _post('${manager.project}/items/$itemId/columns', {'name': name, 'dataType': 'text', 'isRequired': required, 'showInReports': false, 'choices': <Object>[]}, await _tokenOf(manager));
  }

  /// [manager] disables the item [itemId].
  static Future<void> itemDisabled(Person manager, String itemId) async {
    await _post('${manager.project}/items/$itemId/disable', {}, await _tokenOf(manager));
  }

  /// The first category of the project of [manager] that holds an item, and that item.
  static Future<({String categoryId, String itemId})> aCategoryAndItem(Person manager) async {
    final categories = await _getList('${manager.project}/categories', await _tokenOf(manager));
    final category = categories.cast<Map<String, dynamic>>().firstWhere((category) => (category['items'] as List<dynamic>).isNotEmpty);
    return (categoryId: category['id'] as String, itemId: ((category['items'] as List<dynamic>).first as Map<String, dynamic>)['id'] as String);
  }

  /// The name of the category that [entry] files a purchase in, its item and its general table.
  static Future<({String category, String itemId, String itemName, String tableId})> firstPurchaseTable(Person person) async {
    final categories = (await _getList('${person.project}/entry-tables', await _tokenOf(person))).cast<Map<String, dynamic>>();
    for (final category in categories) {
      for (final item in (category['items'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        final tables = (item['tables'] as List<dynamic>).cast<Map<String, dynamic>>().where((table) => table['kind'] == 'general');
        if (item['isRevenue'] == false && tables.isNotEmpty) {
          return (category: category['name'] as String, itemId: item['id'] as String, itemName: item['name'] as String, tableId: tables.first['id'] as String);
        }
      }
    }
    throw StateError('The project offers no table for a purchase');
  }

  /// [manager] adds an account, a bank one unless [custodian] holds it, and its id is answered.
  static Future<String> account(Person manager, {String name = '', Person custodian = Person.none}) async {
    final token = await _tokenOf(manager);
    final accountName = name.isEmpty ? 'Bank ${unique()}' : name;
    await _post('${manager.project}/accounts', {
      'name': accountName,
      'type': custodian.isNone ? 'bank' : 'cashCustody',
      if (!custodian.isNone) 'custodianId': custodian.id,
    }, token);
    final all = await _getList('${manager.project}/accounts', token);
    return all.cast<Map<String, dynamic>>().singleWhere((account) => account['name'] == accountName)['id'] as String;
  }

  /// [manager] puts [amount] into the account [accountId] with approved revenue: money enters an account only through entries and transfers (redix-app #89).
  static Future<void> funded(Person manager, String accountId, num amount) async => entriesApproved(manager, [await revenue(manager, amount: amount, accountId: accountId)]);

  /// [manager] moves [amount] from the account [from] to [to] (FR-23), counted at once in both.
  static Future<void> transferred(Person manager, String from, String to, num amount) async =>
      _post('${manager.project}/transfers', {'fromAccountId': from, 'toAccountId': to, 'amount': amount, 'date': DateTime.now().toIso8601String().substring(0, 10), 'notes': ''}, await _tokenOf(manager));

  /// [manager] disables the account [accountId].
  static Future<void> accountDisabled(Person manager, String accountId) async {
    await _post('${manager.project}/accounts/$accountId/disable', {}, await _tokenOf(manager));
  }

  /// [manager] enters what each account in [balances] really holds.
  static Future<void> reconciled(Person manager, Map<String, num> balances) async {
    await _post('${manager.project}/reconciliations', {
      'balances': [for (final balance in balances.entries) {'accountId': balance.key, 'actualBalance': balance.value}],
    }, await _tokenOf(manager));
  }

  /// The payment methods of the project of [manager], in order.
  static Future<List<Map<String, dynamic>>> paymentMethods(Person manager) async => (await _getList('${manager.project}/payment-methods', await _tokenOf(manager))).cast<Map<String, dynamic>>();

  /// [manager] disables the payment method [methodId].
  static Future<void> paymentMethodDisabled(Person manager, String methodId) async {
    await _post('${manager.project}/payment-methods/$methodId/disable', {}, await _tokenOf(manager));
  }

  /// [manager] adds a partner on the project's capital item, with [login] as their login if given, and their id is answered.
  static Future<String> partner(Person manager, String name, {Person login = Person.none}) async {
    final token = await _tokenOf(manager);
    await _post('${manager.project}/partners', {'name': name, if (!login.isNone) 'userId': login.id}, token);
    final all = await _getList('${manager.project}/partners', token);
    return all.cast<Map<String, dynamic>>().singleWhere((partner) => partner['name'] == name)['id'] as String;
  }

  /// [manager] chooses the partner [partnerId] for [person], who then holds رأس مال شركاء محددين and sees that partner's capital (redix-api #106).
  static Future<void> choosePartner(Person manager, Person person, String partnerId) async {
    await _post('${manager.project}/users/${person.id}/partners/$partnerId', {}, await _tokenOf(manager));
  }

  /// [by] adds a supplier, and its id is answered: approved when [by] keeps the settings, otherwise waiting for approval.
  static Future<String> supplier(Person by, {String name = '', String vatNumber = '', String defaultItemId = ''}) async {
    final made = await _post('${by.project}/suppliers', {'name': name.isEmpty ? 'Supplier ${unique()}' : name, 'vatNumber': vatNumber, if (defaultItemId.isNotEmpty) 'defaultItemId': defaultItemId}, await _tokenOf(by));
    return made['id'] as String;
  }

  /// [manager] disables the supplier [supplierId].
  static Future<void> supplierDisabled(Person manager, String supplierId) async {
    await _post('${manager.project}/suppliers/$supplierId/disable', {}, await _tokenOf(manager));
  }

  /// [manager] adds a contract with a new contractor, and what it made is answered.
  static Future<MadeContract> contract(Person manager, {num value = 1000, bool openValue = false, String contractor = ''}) async {
    final token = await _tokenOf(manager);
    final name = contractor.isEmpty ? 'Contractor ${unique()}' : contractor;
    final supplier = await _post('${manager.project}/suppliers', {'name': name}, token);
    final categories = await _getList('${manager.project}/categories', token);
    final items = categories.expand((category) => category['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final item = items.firstWhere((item) => item['type'] == 'contractorPayments' || item['type'] == 'both');
    await _post('${manager.project}/contracts', {'supplierId': supplier['id'] as String, 'itemId': item['id'] as String, 'value': value, 'isOpenValue': openValue}, token);
    final all = await _getList('${manager.project}/contracts', token);
    final made = all.cast<Map<String, dynamic>>().singleWhere((contract) => contract['supplierName'] == name);
    return (id: made['id'] as String, itemId: item['id'] as String, supplierId: supplier['id'] as String, contractor: name);
  }

  /// The ids of the documents the contract [contractId] of [manager]'s project carries, in the order they were kept.
  static Future<List<String>> contractDocumentIds(Person manager, String contractId) async {
    final all = (await _getList('${manager.project}/contracts', await _tokenOf(manager))).cast<Map<String, dynamic>>();
    return [for (final document in all.singleWhere((contract) => contract['id'] == contractId)['documents'] as List<dynamic>) (document as Map<String, dynamic>)['id'] as String];
  }

  /// [manager] disables the contract [contractId].
  static Future<void> contractDisabled(Person manager, String contractId) async {
    await _post('${manager.project}/contracts/$contractId/disable', {}, await _tokenOf(manager));
  }

  /// [manager] keeps a small document, and its id is answered.
  static Future<String> document(Person manager, {String name = '', String group = ''}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_base${manager.project}/documents'))
      ..headers['Authorization'] = 'Bearer ${await _tokenOf(manager)}'
      ..fields['name'] = name.isEmpty ? 'Document ${unique()}' : name
      ..fields['group'] = group
      ..files.add(http.MultipartFile.fromString('file', 'A test document ${unique()}.', filename: 'document.txt'));
    final answer = await http.Response.fromStream(await request.send());
    return _bodyOf('POST document', answer)['id'] as String;
  }

  /// The id of «مرتجع», the choice of «نوع القيد» that makes a purchase a credit note: the same in every database, as the API's template seeds it (redix-api #129).
  static const creditNoteChoiceId = '6ad91ed9-316c-826e-8f15-e5f277fdeba2';

  /// The id of «سحب مبلغ», the choice of «نوع الحركة» that takes a partner's money out: the same in every database (redix-api #129).
  static const withdrawalChoiceId = '90f8b88a-68ff-f475-364a-5ee21644377d';

  /// The id of «إضافة مبلغ», the choice of «نوع الحركة» that puts a partner's money in (redix-api #129).
  static const contributionChoiceId = '18475559-dc5d-29ae-f1c8-36b2b080151f';

  /// A purchase by [by] on the first general table a purchase can go to, sent for approval or, when [sent] is false, kept as a draft; a credit note when [creditNote], its
  /// «نوع القيد» «مرتجع». Its id is answered.
  static Future<String> entry(Person by, {bool sent = true, num amount = 100, String accountId = '', String supplierId = '', String notes = '', String itemId = '', String tableId = '', String date = '', bool creditNote = false}) async {
    final token = await _tokenOf(by);
    final table = await firstPurchaseTable(by);
    return _record(by, token, {
      'itemId': itemId.isEmpty ? table.itemId : itemId,
      'tableId': tableId.isEmpty ? table.tableId : tableId,
      'amount': amount,
      'accountId': accountId.isEmpty ? await account(by) : accountId,
      'paymentMethodId': await _firstIdOf('${by.project}/payment-methods', token),
      'supplierId': supplierId.isEmpty ? await _firstIdOf('${by.project}/suppliers', token) : supplierId,
      'submit': sent,
      'description': notes,
      if (date.isNotEmpty) 'date': date,
      if (creditNote) 'columnValues': {'entryType': creditNoteChoiceId},
    });
  }

  /// A payment by [manager] on [contract], sent for approval unless [sent] is false. Its id is answered.
  static Future<String> contractorPayment(Person manager, MadeContract contract, {bool sent = true, num amount = 100, String accountId = '', bool outside = false, String notes = ''}) async {
    final token = await _tokenOf(manager);
    return _record(manager, token, {
      'itemId': contract.itemId,
      'tableId': contract.id,
      'amount': amount,
      'accountId': accountId.isEmpty ? await account(manager) : accountId,
      'paymentMethodId': await _firstIdOf('${manager.project}/payment-methods', token),
      'submit': sent,
      'isOutsideContract': outside,
      'description': notes,
    });
  }

  /// Revenue by [manager] on the first revenue item with a table of its own, sent for approval unless [sent] is false. Its id is answered.
  static Future<String> revenue(Person manager, {bool sent = true, num amount = 300, String accountId = ''}) async {
    final token = await _tokenOf(manager);
    final categories = await _getList('${manager.project}/entry-tables', token);
    final items = categories.expand((category) => category['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final item = items.firstWhere((item) => item['isRevenue'] == true && (item['tables'] as List<dynamic>).any((table) => table['kind'] != 'partner'));
    final table = (item['tables'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere((table) => table['kind'] != 'partner');
    return _record(manager, token, {'itemId': item['id'] as String, 'tableId': table['id'] as String, 'amount': amount, 'accountId': accountId.isEmpty ? await account(manager) : accountId, 'submit': sent});
  }

  /// Money the partner [partnerId] put in, or took out with [withdrawal], as «نوع الحركة» says (redix-api #129), entered by [manager]. Its id is answered.
  static Future<String> partnerMoney(Person manager, String partnerId, {bool sent = true, num amount = 500, bool withdrawal = false, String accountId = ''}) async {
    final token = await _tokenOf(manager);
    final categories = await _getList('${manager.project}/entry-tables', token);
    final items = categories.expand((category) => category['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final item = items.firstWhere((item) => (item['tables'] as List<dynamic>).any((table) => table['id'] == partnerId));
    return _record(manager, token, {'itemId': item['id'] as String, 'tableId': partnerId, 'amount': amount, 'accountId': accountId.isEmpty ? await account(manager) : accountId, 'columnValues': {'movementType': withdrawal ? withdrawalChoiceId : contributionChoiceId}, 'submit': sent});
  }

  /// [person] deletes the entry [entryId], which was never approved.
  static Future<void> entryDeleted(Person person, String entryId) async {
    await _delete('${person.project}/entries/$entryId', await _tokenOf(person));
  }

  /// [manager] approves the entries [entryIds].
  static Future<void> entriesApproved(Person manager, List<String> entryIds) async {
    await _post('${manager.project}/entries/approve', {'entryIds': entryIds}, await _tokenOf(manager));
  }

  /// [manager] rejects the entry [entryId], saying [reason].
  static Future<void> entryRejected(Person manager, String entryId, {String reason = 'المبلغ غير صحيح'}) async {
    await _post('${manager.project}/entries/$entryId/reject', {'reason': reason}, await _tokenOf(manager));
  }

  /// [manager] removes the approved entry [entryId] softly (redix-api #119), ticking the removal for themselves first, since nobody holds it until it is ticked.
  static Future<void> entryRemoved(Person manager, String entryId) async {
    await ticked(manager, [Permission.removeApprovedEntries], by: manager);
    await _delete('${manager.project}/entries/$entryId', await _tokenOf(manager));
  }

  /// [manager] issues the next periodic report.
  static Future<void> reportIssued(Person manager) async {
    await _post('${manager.project}/periodic-reports', {}, await _tokenOf(manager));
  }

  /// The ids of what waits for a decision in the project of [manager].
  static Future<List<String>> waitingIds(Person manager) async {
    final waiting = await _getList('${manager.project}/entries/pending', await _tokenOf(manager));
    return [for (final entry in waiting) (entry as Map<String, dynamic>)['id'] as String];
  }

  /// The entries of the project of [person], as the API lists them.
  static Future<List<Map<String, dynamic>>> entries(Person person) async => (await _getList('${person.project}/entries', await _tokenOf(person))).cast<Map<String, dynamic>>();

  /// The archive of the project of [manager], as the API hands it (UC-073): a case retrieves it on the phone.
  static Future<List<int>> archiveOf(Person manager) async {
    final answer = await http.get(Uri.parse('$_base${manager.project}/archive/json'), headers: {'Authorization': 'Bearer ${await _tokenOf(manager)}'});
    if (answer.statusCode != 200) {
      throw StateError('GET archive answered ${answer.statusCode}: ${answer.body}');
    }
    return answer.bodyBytes;
  }

  /// The «رقم القيد» the API gave the entry [entryId] of the project of [person] (redix-api #128): a case learns it here and finds it on the phone.
  static Future<int> numberOf(Person person, String entryId) async => (await entries(person)).singleWhere((row) => row['id'] == entryId)['number'] as int;

  /// The newest lines of the History at [path] of the project of [person], such as `accounts/history`, as the API answers them to [person]: a case learns a line's id
  /// here and finds it on the phone by its key.
  static Future<List<Map<String, dynamic>>> history(Person person, String path) async => (await _getList('${person.project}/$path', await _tokenOf(person))).cast<Map<String, dynamic>>();

  /// The lines of [person]'s own login, newest first, as «سجلي» reads them (redix-api #86).
  static Future<List<Map<String, dynamic>>> myHistory(Person person) async => (await _getList('/me/history', await _tokenOf(person))).cast<Map<String, dynamic>>();

  /// What [person] was told, newest first, as the API lists it.
  static Future<List<Map<String, dynamic>>> notifications(Person person) async => (await _getList('/notifications', await _tokenOf(person))).cast<Map<String, dynamic>>();

  /// The columns of the item [itemId].
  static Future<List<Map<String, dynamic>>> columns(Person manager, String itemId) async => (await _getList('${manager.project}/items/$itemId/columns', await _tokenOf(manager))).cast<Map<String, dynamic>>();

  /// [manager] deletes the column [columnId] of the item [itemId].
  static Future<void> columnDeleted(Person manager, String itemId, String columnId) async {
    await _delete('${manager.project}/items/$itemId/columns/$columnId', await _tokenOf(manager));
  }

  /// [manager] sends the draft [entryId] for approval.
  static Future<void> submitted(Person manager, String entryId) async {
    await _post('${manager.project}/entries/$entryId/submit', {}, await _tokenOf(manager));
  }

  /// The name of the category holding the item [itemId].
  static Future<String> categoryOf(Person manager, String itemId) async {
    final categories = (await _getList('${manager.project}/categories', await _tokenOf(manager))).cast<Map<String, dynamic>>();
    return categories.firstWhere((category) => (category['items'] as List<dynamic>).any((item) => item['id'] == itemId))['name'] as String;
  }

  /// The id of the category named [name] in the project of [manager].
  static Future<String> categoryNamed(Person manager, String name) => idNamed(manager, '${manager.project}/categories', name);

  // The ids of what a case named, each list's from its own route (findings row 236): a case learns an id from the API, never from the screen.

  /// The id of the account named [name] in [person]'s project.
  static Future<String> accountNamed(Person person, String name) => idNamed(person, '${person.project}/accounts', name);

  /// The id of the contract with the contractor named [contractor] in [person]'s project.
  static Future<String> contractWith(Person person, String contractor) => idNamed(person, '${person.project}/contracts', contractor, field: 'supplierName');

  /// The id of the document named [name] in [person]'s project.
  static Future<String> documentNamed(Person person, String name) => idNamed(person, '${person.project}/documents', name);

  /// The id of the table named [name] that Add entry offers [person], as its table picker lists it.
  static Future<String> entryTableNamed(Person person, String name) => idNamed(person, '${person.project}/entry-tables', name, inList: 'tables');

  /// The id of the entry of [amount] [person] sees in their project.
  static Future<String> entryOf(Person person, num amount) => idNamed(person, '${person.project}/entries', '$amount', field: 'amount');

  /// The id of the item named [name] in [person]'s project, in whichever category.
  static Future<String> itemNamed(Person person, String name) => idNamed(person, '${person.project}/categories', name, inList: 'items');

  /// The id of the supplier named [name] in [person]'s project.
  static Future<String> supplierNamed(Person person, String name) => idNamed(person, '${person.project}/suppliers', name);

  /// The id of the partner named [name] in [person]'s project.
  static Future<String> partnerNamed(Person person, String name) => idNamed(person, '${person.project}/partners', name);

  /// The id of the unit named [name] in [person]'s project.
  static Future<String> unitNamed(Person person, String name) => idNamed(person, '/projects', name, inList: 'units');

  /// The id of the project named [name] on [person]'s list of projects.
  static Future<String> projectNamed(Person person, String name) => idNamed(person, '/projects', name);

  /// The id of the payment method named [name] in [person]'s project.
  static Future<String> paymentMethodNamed(Person person, String name) => idNamed(person, '${person.project}/payment-methods', name);

  /// The id of the column named [name] of the item [itemId].
  static Future<String> columnNamed(Person person, String itemId, String name) => idNamed(person, '${person.project}/items/$itemId/columns', name);

  /// The id of the column named [name] of the template the item [itemId] is made from: its project's default columns for the item's type.
  static Future<String> templateColumnNamed(Person person, String itemId, String name) async {
    final items = _rowsUnder(await _get('${person.project}/categories', await _tokenOf(person)), 'items');
    final type = items.singleWhere((item) => item['id'] == itemId)['type'];
    return idNamed(person, '${person.project}/default-columns/$type', name);
  }

  /// The id of the table named [name] of the item [itemId].
  static Future<String> tableNamed(Person person, String itemId, String name) => idNamed(person, '${person.project}/items/$itemId/tables', name);

  /// The id of the person called [displayName] in [person]'s project.
  static Future<String> userNamed(Person person, String displayName) => idNamed(person, '${person.project}/users', displayName, field: 'displayName');

  /// Whether the API lets [username] sign in with [password] now.
  static Future<bool> canSignIn(String username, String password) async => (await _signIn(username, password)).statusCode == 200;

  static Future<String> _record(Person by, String token, Map<String, Object> body) async {
    final id = const Uuid().v7();
    await _post('${by.project}/entries', {'id': id, 'date': _today, ...body}, token);
    return id;
  }

  static Future<String> _firstIdOf(String path, String token) async => ((await _getList(path, token)).first as Map<String, dynamic>)['id'] as String;

  static Future<String> _tokenOf(Person person) async => (await _signedIn(person.username, person.password))['accessToken'] as String;

  /// The admin's token. The API seeds the admin with a temporary password, so the first case of a run changes it.
  static Future<String> _adminToken() async {
    if (!await canSignIn(_adminUsername, _adminPassword)) {
      final first = await _signedIn(_adminUsername, _adminTemporaryPassword);
      await _post('/auth/change-password', {'currentPassword': _adminTemporaryPassword, 'newPassword': _adminPassword}, first['accessToken'] as String);
    }
    return (await _signedIn(_adminUsername, _adminPassword))['accessToken'] as String;
  }

  static Future<http.Response> _signIn(String username, String password) =>
      http.post(Uri.parse('$_base/auth/sign-in'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'password': password}));

  static Future<Map<String, dynamic>> _signedIn(String username, String password) async => _bodyOf('sign-in of $username', await _signIn(username, password));

  static Future<Map<String, dynamic>> _post(String path, Map<String, Object> body, [String token = '']) async {
    final answer = await http.post(Uri.parse('$_base$path'), headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'}, body: jsonEncode(body));
    return _bodyOf('POST $path', answer);
  }

  static Future<void> _put(String path, Map<String, Object> body, String token) async {
    final answer = await http.put(Uri.parse('$_base$path'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(body));
    _bodyOf('PUT $path', answer);
  }

  static Future<void> _delete(String path, String token) async => _bodyOf('DELETE $path', await http.delete(Uri.parse('$_base$path'), headers: {'Authorization': 'Bearer $token'}));

  static Future<List<dynamic>> _getList(String path, String token) async => await _get(path, token) as List<dynamic>;

  static Future<Object?> _get(String path, String token) async {
    final answer = await http.get(Uri.parse('$_base$path'), headers: {'Authorization': 'Bearer $token'});
    if (answer.statusCode != 200) {
      throw StateError('GET $path answered ${answer.statusCode}: ${answer.body}');
    }
    return jsonDecode(utf8.decode(answer.bodyBytes));
  }

  /// The id of the one row named [name] in what the API answers at [path] for [person] (findings row 236): a case learns the id of what it made from the API, never from the
  /// screen. [inList] names the lists its rows sit in, such as each category's `items`; empty for a list the API answers whole. [field] is what names a row, compared as a
  /// number when the API holds one there. Fails unless exactly one row is named so.
  static Future<String> idNamed(Person person, String path, String name, {String inList = '', String field = 'name'}) async {
    final answer = await _get(path, await _tokenOf(person));
    bool named(Map<String, dynamic> row) => row[field] is num ? row[field] == num.tryParse(name) : '${row[field]}' == name;
    final rows = (inList.isEmpty ? (answer! as List<dynamic>).whereType<Map<String, dynamic>>() : _rowsUnder(answer, inList)).where(named).toList();
    if (rows.length != 1) {
      throw StateError('GET $path holds ${rows.length} rows whose $field is $name');
    }
    return rows.single['id'] as String;
  }

  /// Every row of every list held under the name [inList] anywhere in [json].
  static Iterable<Map<String, dynamic>> _rowsUnder(Object? json, String inList) sync* {
    if (json is List<dynamic>) {
      for (final element in json) {
        yield* _rowsUnder(element, inList);
      }
    } else if (json is Map<String, dynamic>) {
      for (final entry in json.entries) {
        if (entry.key == inList && entry.value is List<dynamic>) {
          yield* (entry.value as List<dynamic>).whereType<Map<String, dynamic>>();
        }
        yield* _rowsUnder(entry.value, inList);
      }
    }
  }

  static Map<String, dynamic> _bodyOf(String what, http.Response answer) {
    if (answer.statusCode >= 300) {
      throw StateError('$what answered ${answer.statusCode}: ${answer.body}');
    }
    return answer.body.isEmpty ? {} : jsonDecode(utf8.decode(answer.bodyBytes)) as Map<String, dynamic>;
  }
}
