import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redix/attachments/invoice_capture.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/biometrics.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/main.dart';
import 'package:redix/words/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The words the fake API serves: each key's value names its language and key, so a test reads which word is shown.
Map<String, String> wordsIn(String language) => {
  for (final key in [
    'app.title',
    'biometrics.signIn', 'biometrics.hint', 'biometrics.or', 'biometrics.failed', 'biometrics.usePassword', 'biometrics.promptTitle', 'biometrics.promptCancel', 'biometrics.notAvailable', 'biometrics.notChanged',
    'projects.choose', 'projects.chooseHint', 'projects.defaultProject', 'projects.openDefault', 'projects.openDefaultHint', 'settings.switchProject',
    'signIn.username', 'signIn.password', 'signIn.hint', 'signIn.submit', 'signIn.forgotPassword',
    'signIn.invalidCredentials', 'signIn.accountLocked', 'signIn.sessionExpired', 'signIn.noConnection',
    'changePassword.title', 'changePassword.hint', 'changePassword.current', 'changePassword.new', 'changePassword.confirm',
    'changePassword.submit', 'changePassword.mismatch', 'changePassword.invalidCredentials', 'changePassword.accountLocked',
    'changePassword.weakPassword', 'changePassword.noConnection',
    'myAccount.title', 'myAccount.language', 'myAccount.arabic', 'myAccount.english', 'myAccount.languageNeedsNetwork',
    'users.roles', 'users.rolesHint', 'users.roleManager', 'users.roleFinance', 'users.roleField', 'users.roleReader',
    'users.addExisting', 'users.unknownUser', 'users.invalidRole', 'users.lastManager', 'users.otherProject',
    'signIn.registerProject', 'register.hint', 'register.sent', 'register.tooManyTries', 'register.invalidName', 'register.invalidUsername',
    'register.invalidMobile', 'register.weakPassword', 'register.usernameTaken', 'register.noConnection', 'register.refused',
    'projects.pending', 'projects.rejected', 'registered.title', 'registered.empty', 'registered.loadFailed', 'registered.approve', 'registered.reject',
    'registered.reason', 'registered.invalidReason', 'registered.notPending', 'registered.noConnection', 'registered.refused',
    'myAccount.changePassword', 'myAccount.signOut', 'myAccount.signOutQuestion', 'myAccount.signOutExplain',
    'settings.title', 'projects.new', 'projects.empty', 'projects.loadFailed', 'common.retry', 'projects.running',
    'projects.finished', 'projects.readOnly', 'projects.startDate', 'projects.name', 'projects.units', 'projects.noUnits',
    'projects.unitName', 'projects.addUnit', 'projects.removeUnit', 'projects.create', 'common.cancel', 'projects.close',
    'projects.closeQuestion', 'projects.closeExplain', 'projects.invalidName', 'projects.projectFinished', 'projects.noConnection',
    'projects.refused',
    'users.title', 'users.new', 'users.loadFailed', 'users.disabled', 'users.edit', 'users.resetPassword', 'users.disable',
    'users.enable', 'users.name', 'users.nameHint', 'users.username', 'users.mobile', 'users.temporaryPassword',
    'users.temporaryPasswordHint', 'users.add', 'users.save', 'users.disableQuestion', 'users.disableExplain', 'users.resetExplain',
    'users.invalidName', 'users.invalidUsername', 'users.invalidMobile', 'users.usernameTaken', 'users.weakPassword',
    'users.noConnection', 'users.refused',
    'columns.title', 'columns.template', 'columns.thisItem', 'columns.hint', 'columns.empty', 'columns.loadFailed', 'columns.noConnection', 'columns.refused', 'columns.projectFinished',
    'columns.invalidName', 'columns.invalidOrder', 'columns.invalidDataType', 'columns.invalidOptions', 'columns.coreColumn', 'columns.new', 'columns.name', 'columns.type', 'columns.typeText',
    'columns.typeNumber', 'columns.typeAmount', 'columns.typeDate', 'columns.typeList', 'columns.typeFile', 'columns.choices', 'columns.required', 'columns.optional', 'columns.showInReports',
    'columns.inReports', 'columns.custom', 'columns.core', 'columns.edit', 'columns.delete', 'columns.save', 'columns.deleteExplain', 'columns.applyQuestion', 'columns.applyExplain',
    'columns.applyToAll', 'columns.templateOnly',
    'categories.title', 'categories.hint', 'categories.empty', 'categories.loadFailed', 'categories.noConnection', 'categories.refused', 'categories.projectFinished',
    'categories.invalidName', 'categories.invalidOrder', 'categories.generalSubgroup', 'categories.new', 'categories.categoryName', 'categories.items', 'categories.noItems',
    'categories.addItem', 'categories.itemName', 'categories.itemType', 'categories.typePurchases', 'categories.typeContractorPayments', 'categories.typeBoth', 'categories.rename',
    'categories.disable', 'categories.enable', 'categories.disabled', 'categories.save', 'categories.subgroups', 'categories.subgroupsHint', 'categories.noSubgroups',
    'subgroups.new', 'categories.subgroupName', 'projects.structureSource', 'projects.defaultTemplate', 'projects.unknownSource',
    'projects.invalidVatRate', 'common.add', 'paymentMethods.title', 'paymentMethods.empty', 'paymentMethods.loadFailed', 'paymentMethods.noConnection', 'paymentMethods.refused', 'paymentMethods.projectFinished',
    'paymentMethods.invalidName', 'paymentMethods.new', 'paymentMethods.name', 'paymentMethods.rename', 'paymentMethods.save', 'paymentMethods.disable', 'paymentMethods.enable', 'paymentMethods.disabled',
    'paymentMethods.vatRate', 'paymentMethods.vatHint', 'paymentMethods.changeVatRate', 'paymentMethods.vatPercent',
    'accounts.title', 'accounts.empty', 'accounts.loadFailed', 'accounts.noConnection', 'accounts.refused', 'accounts.projectFinished', 'accounts.invalidName', 'accounts.invalidOpeningBalance',
    'accounts.custodianRequired', 'accounts.unknownCustodian', 'accounts.new', 'accounts.edit', 'accounts.save', 'accounts.type', 'accounts.typeBank', 'accounts.typeCashCustody', 'accounts.name',
    'partners.title', 'partners.empty', 'partners.loadFailed', 'partners.noConnection', 'partners.refused', 'partners.projectFinished', 'partners.invalidName', 'partners.unknownUser', 'partners.userTaken',
    'partners.new', 'partners.edit', 'partners.save', 'partners.name', 'partners.login', 'partners.noLogin', 'partners.loginHint',
    'suppliers.title', 'suppliers.empty', 'suppliers.loadFailed', 'suppliers.noConnection', 'suppliers.refused', 'suppliers.projectFinished', 'suppliers.invalidName', 'suppliers.invalidVatNumber',
    'suppliers.invalidMobile', 'suppliers.vatNumberTaken', 'suppliers.holder', 'suppliers.unknownItem', 'suppliers.new', 'suppliers.edit', 'suppliers.save', 'suppliers.name', 'suppliers.vatNumber',
    'suppliers.notVatRegistered', 'suppliers.mobile', 'suppliers.defaultItem', 'suppliers.noDefaultItem', 'suppliers.pendingApproval', 'suppliers.disable', 'suppliers.enable', 'suppliers.disabled',
    'suppliers.pick', 'suppliers.searchHint', 'suppliers.noMatch', 'suppliers.quickAdd', 'suppliers.addAndPick', 'suppliers.pendingHint', 'suppliers.useExisting',
    'contracts.title', 'contracts.empty', 'contracts.loadFailed', 'contracts.noConnection', 'contracts.refused', 'contracts.projectFinished', 'contracts.unknownSupplier', 'contracts.itemNotOffered',
    'contracts.unknownUnit', 'contracts.invalidValue', 'contracts.invalidUnitPrice', 'contracts.invalidQuantity', 'contracts.invalidNotes', 'contracts.new', 'contracts.edit', 'contracts.save',
    'contracts.contractor', 'contracts.item', 'contracts.unit', 'contracts.openValue', 'contracts.contractValue', 'contracts.unitPrice', 'contracts.quantity', 'contracts.notes', 'contracts.value',
    'contracts.paid', 'contracts.remaining', 'contracts.open', 'contracts.overrun', 'contracts.notStarted', 'contracts.running', 'contracts.filterAll', 'contracts.filterOverrun',
    'contracts.filterOpenValue', 'contracts.disable', 'contracts.enable', 'contracts.disabled', 'contracts.documents', 'contracts.addDocument', 'contracts.unknownAttachment',
    'attachments.invalidFileType', 'attachments.imageTooLarge', 'attachments.projectFinished', 'attachments.noConnection', 'attachments.refused', 'attachments.cameraFailed', 'attachments.unreadable',
    'attachments.invoicePhoto', 'attachments.retake', 'attachments.takePhoto', 'attachments.pickFile', 'expenses.new',
    'expenses.item', 'expenses.subgroup', 'expenses.generalSubgroup', 'expenses.unit', 'expenses.supplier', 'expenses.invoiceNumber', 'expenses.invoiceDate', 'expenses.product', 'expenses.unitPrice', 'expenses.quantity',
    'expenses.includingVat', 'expenses.beforeVat', 'expenses.amountIncludingVat', 'expenses.amountBeforeVat', 'expenses.discount', 'expenses.notTaxable', 'expenses.afterDiscount', 'expenses.vat', 'expenses.total',
    'expenses.paymentSource', 'expenses.paymentMethod', 'expenses.account', 'expenses.noAccount', 'expenses.paymentDiffers', 'expenses.paymentDate', 'expenses.paymentAmount', 'expenses.bankFees', 'expenses.notes',
    'expenses.send', 'expenses.saveDraft', 'expenses.sent', 'expenses.saved', 'expenses.noConnection', 'expenses.refused', 'expenses.projectFinished', 'expenses.invalidEntryId',
    'expenses.entryExists', 'expenses.itemNotOffered', 'expenses.unknownSubgroup', 'expenses.unknownUnit', 'expenses.unknownSupplier', 'expenses.unknownPaymentMethod', 'expenses.accountNotOffered', 'expenses.unknownAttachment',
    'expenses.invalidInvoiceNumber', 'expenses.invalidProduct', 'expenses.invalidNotes', 'expenses.invalidUnitPrice', 'expenses.invalidQuantity', 'expenses.invalidAmount', 'expenses.invalidDiscount', 'expenses.invalidPaymentAmount',
    'expenses.invalidBankFees', 'expenses.invalidInvoiceDate', 'expenses.invalidPaymentDate', 'expenses.unknownColumn', 'expenses.invalidColumnValue', 'expenses.requiredColumnMissing', 'expenses.invoiceRequired', 'expenses.qrRead',
    'expenses.qrUnreadable', 'expenses.qrSupplierMissing', 'expenses.qrAddSupplier', 'expenses.qrVatDiffers', 'suppliers.mostUsed',
    'expenses.duplicateInvoice', 'expenses.duplicateTitle', 'expenses.duplicateExplain', 'expenses.duplicateHidden', 'expenses.saveAnyway', 'expenses.invoiceAlreadyAttached',
    'expenses.withoutInvoice', 'expenses.withoutInvoiceReason', 'expenses.invalidWithoutInvoiceReason', 'expenses.invoiceAndReason', 'expenses.amount',
    'accounts.custodian', 'accounts.noCustodian', 'accounts.openingBalance', 'accounts.disable', 'accounts.enable', 'accounts.disabled', 'accounts.myCustody', 'accounts.riyal',
  ])
    key: '$language $key',
};

/// A kept session, as the secure storage holds it after a sign-in.
const keptSession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false}';

/// A kept session on a phone that uses a fingerprint or face.
const keptBiometricSession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "usesBiometrics": true}';

/// A kept session whose password is temporary.
const keptTemporarySession = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": true}';

/// What the admin holds everywhere.
const admin = ['approveProjects'];

/// What a project manager who also does the finance may do in a project.
const managerAndFinance = ['manageUsers', 'readProject', 'seeAllCapital', 'manageProject', 'manageStructure', 'manageSettings', 'addSupplier', 'recordEntries', 'attachFiles', 'chargeAnyAccount'];

/// What someone in the field may do in a project.
const field = ['readProject', 'addSupplier', 'recordEntries', 'attachFiles'];

/// A picture of one pixel, which a test can draw.
const onePixelPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0, 0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// The phone's camera and files, as the app's tests see them: each answers what the test chose, and nothing until it chooses.
class FakeCapture extends InvoiceCapture {
  /// What the camera answers.
  var camera = PickedFile.none();

  /// What the files answer.
  var files = PickedFile.none();

  /// What the phone's barcode reader finds in any picture; empty for nothing.
  var qrText = '';

  /// How many pictures the barcode reader looked at.
  var qrReads = 0;

  /// How many times the camera opened.
  var cameraOpened = 0;

  @override
  Future<String> qrTextOf(PickedFile file) async {
    qrReads++;
    return qrText;
  }

  @override
  Future<PickedFile> fromCamera() async {
    cameraOpened++;
    return camera;
  }

  @override
  Future<PickedFile> fromFiles() async => files;
}

/// The phone's own fingerprint or face prompt, as the app's tests see it.
class FakePrompt extends Fake implements FlutterSecureStorage {
  /// What a read answers once the prompt passes: the fixed word, or nothing once a new fingerprint was added to the phone.
  String? answer = 'on';

  /// Whether the prompt fails, like a wrong finger, a locked sensor or a phone with no fingerprint.
  var fails = false;

  /// Whether the prompt never answers, like Cancel on Android.
  var neverAnswers = false;

  /// How many times the prompt has shown.
  var shown = 0;

  /// What the prompt was last told to show on Android.
  var options = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    shown++;
    options = aOptions?.toMap() ?? {};
    if (neverAnswers) {
      return Completer<String?>().future;
    }
    if (fails) {
      throw PlatformException(code: 'Exception encountered', message: 'Biometric authentication error');
    }
    return Future.value(answer);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (fails) {
      throw PlatformException(code: 'Exception encountered', message: 'BIOMETRIC_UNAVAILABLE');
    }
  }
}

/// The API as the app's tests see it: words for any language, and the answers of sign-in, refresh and password change each test chooses.
class FakeApi {
  /// Whether the network is up; when false every request fails like a phone without signal.
  var online = true;

  /// The status and problem code `POST /auth/sign-in` answers; 200 opens a session.
  var signInAnswer = (status: 200, code: '');

  /// Whether the user's password is temporary: sign-in and refresh report it, and a successful change clears it.
  var mustChangePassword = false;

  /// The status `POST /auth/refresh` answers; 200 renews the session.
  var refreshStatus = 200;

  /// The status and problem code `POST /auth/change-password` answers; 200 changes the password.
  var changePasswordAnswer = (status: 200, code: '');

  /// What the signed-in user holds everywhere: every session says so.
  var permissions = <String>[];

  /// The project the signed-in user chose to land on, as every session says it; empty when none.
  var defaultProjectId = '';

  /// Whether sign-in opens the default project directly, as every session says it.
  var openDefaultProject = false;

  /// Whether this phone uses a fingerprint or face, as every session says it.
  var usesBiometrics = false;

  /// What turning a fingerprint or face on or off answers.
  var biometricsStatus = 200;

  /// What was last sent to turn a fingerprint or face on or off.
  final sentBiometrics = <bool>[];

  /// The roles a project can give, in their order.
  final roles = <Map<String, String>>[
    {'id': 'role-manager', 'wordKey': 'users.roleManager'},
    {'id': 'role-finance', 'wordKey': 'users.roleFinance'},
    {'id': 'role-field', 'wordKey': 'users.roleField'},
    {'id': 'role-reader', 'wordKey': 'users.roleReader'},
  ];

  /// The projects the API holds, as it answers them.
  final projects = <Map<String, Object>>[];

  /// The status and problem code the API answers to a change of a project; 2xx makes the change. An empty code sends none.
  var projectAnswer = (status: 200, code: '');

  /// The projects waiting for the admin, as the API answers them.
  final registered = <Map<String, Object>>[];

  /// The status and problem code the API answers to a registration or a decision; 2xx makes it. An empty code sends none.
  var registrationAnswer = (status: 200, code: '');

  /// The registrations and decisions the app sent, as `path` and body.
  final sentRegistrations = <(String, Map<String, dynamic>)>[];

  /// The changes of a project the app sent, as `path` and body.
  final sentProjectChanges = <(String, Map<String, dynamic>)>[];

  /// The users the API holds, as it answers them.
  final users = <Map<String, Object>>[];

  /// The status and problem code the API answers to a change of a user; 2xx makes the change. An empty code sends none.
  var userAnswer = (status: 200, code: '');

  /// The changes of a user the app sent, as `path` and body.
  final sentUserChanges = <(String, Map<String, dynamic>)>[];

  /// Each project's categories, as the API answers them.
  final categories = <String, List<Map<String, Object>>>{};

  /// The status and problem code the API answers to a change of the structure; 2xx makes the change. An empty code sends none.
  var structureAnswer = (status: 200, code: '');

  /// The changes of the structure the app sent, as `path` and body.
  final sentStructureChanges = <(String, Map<String, dynamic>)>[];

  /// The columns the API holds, by the address they are read at.
  final columns = <String, List<Map<String, Object>>>{};

  /// Each project's payment methods, as the API answers them.
  final paymentMethods = <String, List<Map<String, Object>>>{};

  /// Each project's accounts, as the API answers them.
  final accounts = <String, List<Map<String, Object>>>{};

  /// Each project's partners, as the API answers them.
  final partners = <String, List<Map<String, Object>>>{};

  /// Each project's supplier register, as the API answers it.
  final suppliers = <String, List<Map<String, Object>>>{};

  /// The supplier the API names in a refused change of a supplier; empty names none.
  var supplierHolder = const <String, Object>{};

  /// What the app asked the supplier search, in order.
  final supplierSearches = <String>[];

  /// While a search for one of these is asked, its answer waits for the completer.
  final heldSupplierSearches = <String, Completer<void>>{};

  /// Each project's contracts, as the API answers them.
  final contracts = <String, List<Map<String, Object>>>{};

  /// The files the app sent, as the bytes of each request read as text, which name each file.
  final sentAttachments = <String>[];

  /// The status and problem code the API answers to a file; 2xx keeps it. An empty code sends none.
  var attachmentAnswer = (status: 201, code: '');

  /// The expenses the app sent, as their bodies.
  final sentExpenses = <Map<String, dynamic>>[];

  /// The status and answer the API gives an expense; 2xx records it.
  var expenseAnswer = (status: 201, body: const <String, dynamic>{});

  /// The people of every project, as the API answers them.
  final members = <Map<String, String>>[];

  /// The status and problem code the API answers to a change of a project's settings; 2xx makes the change. An empty code sends none.
  var settingsAnswer = (status: 200, code: '');

  /// The changes of a project's settings the app sent, as `path` and body.
  final sentSettingsChanges = <(String, Map<String, dynamic>)>[];

  var _nextStructureId = 0;

  /// How many times the app renewed its session.
  var refreshes = 0;

  /// How many times the app told the API it signed out.
  var signOuts = 0;

  /// Refresh tokens already replaced. One sent again answers 401, as the real API answers it.
  final _replacedRefreshTokens = <String>{};

  /// How many sessions the API has issued, so that each gets a refresh token of its own.
  var _issued = 0;

  /// Access tokens the API treats as expired, answering 401 with no body.
  final expiredAccessTokens = <String>{};

  /// The access tokens the app sent, in order.
  final sentAccessTokens = <String>[];

  /// The client the app's requests reach.
  late final client = MockClient((request) async {
    if (!online) {
      throw http.ClientException('offline');
    }
    final path = request.url.path;
    if (path.startsWith('/translations/')) {
      return http.Response.bytes(utf8.encode(jsonEncode(wordsIn(request.url.pathSegments.last))), 200, headers: {'etag': '"1"'});
    }
    final accessToken = (request.headers['Authorization'] ?? '').replaceFirst('Bearer ', '');
    if (path == '/auth/change-password' || path.startsWith('/projects') || path.startsWith('/users')) {
      sentAccessTokens.add(accessToken);
      if (expiredAccessTokens.contains(accessToken)) {
        return http.Response('', 401);
      }
    }
    if (path == '/auth/sign-out') {
      signOuts++;
      return http.Response('', 204);
    }
    if (path.startsWith('/projects')) {
      return _answerProjects(request);
    }
    if (path.startsWith('/users')) {
      return _answerUsers(request);
    }
    if (path == '/auth/sign-in') {
      usesBiometrics = false;
    }
    if (path == '/auth/refresh') {
      refreshes++;
      final refreshToken = (jsonDecode(request.body) as Map<String, dynamic>)['refreshToken'] as String;
      if (_replacedRefreshTokens.contains(refreshToken)) {
        return http.Response('{"code": "sessionExpired"}', 401);
      }
      if (refreshStatus == 200) {
        _replacedRefreshTokens.add(refreshToken);
      }
    }
    if (path == '/auth/biometrics') {
      final on = (jsonDecode(request.body) as Map<String, dynamic>)['on'] as bool;
      sentBiometrics.add(on);
      usesBiometrics = biometricsStatus == 200 ? on : usesBiometrics;
    }
    final (status, code) = switch (path) {
      '/auth/sign-in' => (signInAnswer.status, signInAnswer.code),
      '/auth/biometrics' => (biometricsStatus, 'refused'),
      '/auth/refresh' => (refreshStatus, 'sessionExpired'),
      _ => (changePasswordAnswer.status, changePasswordAnswer.code),
    };
    if (path == '/auth/change-password' && status == 200) {
      mustChangePassword = false;
    }
    final body = status == 200
        ? '{"accessToken": "new-access", "refreshToken": "new-refresh-${_issued++}", "mustChangePassword": $mustChangePassword, "permissions": ${jsonEncode(permissions)}, "defaultProjectId": "$defaultProjectId", "openDefaultProject": $openDefaultProject, "usesBiometrics": $usesBiometrics}'
        : '{"code": "$code"}';
    return http.Response(body, status);
  });

  /// Adds a project to what the API holds, with [units] named in order.
  Map<String, Object> addProject(
    String name, {
    String status = 'running',
    String startDate = '2026-03-01',
    List<String> units = const [],
    String rejectionReason = '',
    List<String> roles = const ['users.roleManager', 'users.roleFinance'],
    List<String> permissions = managerAndFinance,
  }) {
    final id = 'project-${projects.length}';
    final project = <String, Object>{
      'id': id,
      'name': name,
      'startDate': startDate,
      'status': status,
      'rejectionReason': rejectionReason,
      'units': [for (final (index, unit) in units.indexed) {'id': '$id-unit-$index', 'name': unit}],
      'entryUnits': [for (final (index, unit) in units.indexed) {'id': '$id-unit-$index', 'name': unit}, {'id': '$id-unit-shared', 'name': 'مشترك'}],
      'roles': roles,
      'permissions': permissions,
      'vatPercent': 15.0,
    };
    projects.add(project);
    return project;
  }

  /// Adds a payment method to the project [projectId], as the API holds it.
  Map<String, Object> addPaymentMethod(String projectId, String name, {bool isActive = true}) {
    final method = <String, Object>{'id': 'method-${_nextStructureId++}', 'name': name, 'isActive': isActive};
    paymentMethods.putIfAbsent(projectId, () => []).add(method);
    return method;
  }

  http.Response _answerPaymentMethods(http.Request request) {
    final segments = request.url.pathSegments;
    final list = paymentMethods.putIfAbsent(segments[1], () => []);
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentSettingsChanges.add((request.url.path, body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    switch (segments.sublist(3)) {
      case []:
        addPaymentMethod(segments[1], body['name'] as String);
      case [final id, 'disable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = false;
      case [final id, 'enable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = true;
      case [final id]:
        list.singleWhere((row) => row['id'] == id)['name'] = body['name'] as String;
    }
    return _json({}, 200);
  }

  /// Adds someone to the people every project can choose among.
  void addMember(String id, String displayName) => members.add({'id': id, 'displayName': displayName});

  /// Adds an account to the project [projectId], as the API holds it.
  Map<String, Object> addAccount(
    String projectId,
    String name, {
    String type = 'bank',
    double openingBalance = 0,
    String custodianId = '',
    String custodianName = '',
    bool isMine = false,
    bool isActive = true,
  }) {
    final account = <String, Object>{
      'id': 'account-${_nextStructureId++}',
      'type': type,
      'name': name,
      'openingBalance': openingBalance,
      'balance': openingBalance,
      'custodianId': custodianId,
      'custodianName': custodianName,
      'isMine': isMine,
      'isActive': isActive,
    };
    accounts.putIfAbsent(projectId, () => []).add(account);
    return account;
  }

  String _memberName(String id) => members.where((member) => member['id'] == id).map((member) => member['displayName']!).join();

  http.Response _answerAccounts(http.Request request) {
    final segments = request.url.pathSegments;
    final list = accounts.putIfAbsent(segments[1], () => []);
    if (segments.last == 'offered') {
      final chargesAny = (projects.singleWhere((project) => project['id'] == segments[1])['permissions']! as List<String>).contains('chargeAnyAccount');
      return _json(list.where((row) => (row['isActive']! as bool) && (chargesAny || (row['isMine']! as bool))).toList(), 200);
    }
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentSettingsChanges.add((request.url.path, body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    final custodianId = body['custodianId'] as String? ?? '';
    switch (segments.sublist(3)) {
      case []:
        addAccount(
          segments[1],
          body['name'] as String,
          type: body['type'] as String,
          openingBalance: body['openingBalance'] as double,
          custodianId: custodianId,
          custodianName: _memberName(custodianId),
        );
      case [final id, 'disable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = false;
      case [final id, 'enable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = true;
      case [final id]:
        list.singleWhere((row) => row['id'] == id)
          ..['name'] = body['name'] as String
          ..['openingBalance'] = body['openingBalance'] as double
          ..['balance'] = body['openingBalance'] as double
          ..['custodianId'] = custodianId
          ..['custodianName'] = _memberName(custodianId);
    }
    return _json({}, 200);
  }

  /// Adds a partner to the project [projectId], as the API holds them.
  Map<String, Object> addPartner(String projectId, String name, {String userId = '', String userName = ''}) {
    final partner = <String, Object>{'id': 'partner-${_nextStructureId++}', 'name': name, 'userId': userId, 'userName': userName};
    partners.putIfAbsent(projectId, () => []).add(partner);
    return partner;
  }

  http.Response _answerPartners(http.Request request) {
    final segments = request.url.pathSegments;
    final list = partners.putIfAbsent(segments[1], () => []);
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentSettingsChanges.add((request.url.path, body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    final userId = body['userId'] as String? ?? '';
    if (segments.length == 3) {
      addPartner(segments[1], body['name'] as String, userId: userId, userName: _memberName(userId));
    } else {
      list.singleWhere((row) => row['id'] == segments[3])
        ..['name'] = body['name'] as String
        ..['userId'] = userId
        ..['userName'] = _memberName(userId);
    }
    return _json({}, 200);
  }

  /// Adds a supplier to the project [projectId], as the API holds it.
  Map<String, Object> addSupplier(
    String projectId,
    String name, {
    String vatNumber = '',
    String mobile = '',
    String defaultItemId = '',
    String defaultItemName = '',
    String status = 'approved',
    bool isActive = true,
    int timesUsed = 0,
  }) {
    final supplier = <String, Object>{
      'id': 'supplier-${_nextStructureId++}',
      'name': name,
      'vatNumber': vatNumber,
      'mobile': mobile,
      'defaultItemId': defaultItemId,
      'defaultItemName': defaultItemName,
      'status': status,
      'isActive': isActive,
      'timesUsed': timesUsed,
    };
    suppliers.putIfAbsent(projectId, () => []).add(supplier);
    return supplier;
  }

  http.Response _answerSuppliers(http.Request request) {
    final segments = request.url.pathSegments;
    final list = suppliers.putIfAbsent(segments[1], () => []);
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    return _changeSuppliers(request, list);
  }

  Future<http.Response> _searchSuppliers(http.Request request) async {
    final text = request.url.queryParameters['text']!;
    supplierSearches.add(text);
    await heldSupplierSearches[text]?.future;
    bool matches(Map<String, Object> row) => (row['isActive']! as bool) && (text.length < 3 || (row['name']! as String).contains(text) || (row['vatNumber']! as String).contains(text));
    return _json(suppliers.putIfAbsent(request.url.pathSegments[1], () => []).where(matches).toList(), 200);
  }

  http.Response _changeSuppliers(http.Request request, List<Map<String, Object>> list) {
    final segments = request.url.pathSegments;
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentSettingsChanges.add((request.url.path, body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code, if (supplierHolder.isNotEmpty) 'existing': supplierHolder}, settingsAnswer.status);
    }
    final vatNumber = body['vatNumber'] as String? ?? '';
    final mobile = body['mobile'] as String? ?? '';
    final defaultItemId = body['defaultItemId'] as String? ?? '';
    final itemName = [for (final category in categories[segments[1]] ?? const <Map<String, Object>>[]) ...category['items']! as List<Map<String, Object>>].where((item) => item['id'] == defaultItemId).map((item) => item['name']! as String).join();
    switch (segments.sublist(3)) {
      case []:
        final keepsSettings = (projects.singleWhere((project) => project['id'] == segments[1])['permissions']! as List<String>).contains('manageSettings');
        return _json(addSupplier(segments[1], body['name'] as String, vatNumber: vatNumber, mobile: mobile, defaultItemId: defaultItemId, defaultItemName: itemName, status: keepsSettings ? 'approved' : 'pendingApproval'), 201);
      case [final id, 'disable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = false;
      case [final id, 'enable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = true;
      case [final id]:
        list.singleWhere((row) => row['id'] == id)
          ..['name'] = body['name'] as String
          ..['vatNumber'] = vatNumber
          ..['mobile'] = mobile
          ..['defaultItemId'] = defaultItemId
          ..['defaultItemName'] = itemName;
    }
    return _json({}, 200);
  }

  /// Adds a contract to the project [projectId], as the API holds it: its remaining reckoned as the API reckons it.
  Map<String, Object> addContract(
    String projectId,
    String supplierName, {
    String itemName = 'البلاط',
    String unitName = 'الفلة الغربية',
    double value = 0,
    bool isOpenValue = false,
    double unitPrice = 0,
    double quantity = 0,
    String notes = '',
    double paid = 0,
    bool isActive = true,
  }) {
    final contract = <String, Object>{
      'id': 'contract-${_nextStructureId++}',
      'supplierName': supplierName,
      'itemName': itemName,
      'unitName': unitName,
      'value': value,
      'isOpenValue': isOpenValue,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'notes': notes,
      'paid': paid,
      'remaining': isOpenValue ? 0.0 : value - paid,
      'isOverrun': !isOpenValue && paid > value,
      'isActive': isActive,
      'documents': <Map<String, String>>[],
    };
    contracts.putIfAbsent(projectId, () => []).add(contract);
    return contract;
  }

  http.Response _answerContracts(http.Request request) {
    final segments = request.url.pathSegments;
    final list = contracts.putIfAbsent(segments[1], () => []);
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentSettingsChanges.add((request.url.path, body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    switch (segments.sublist(3)) {
      case []:
        addContract(
          segments[1],
          suppliers[segments[1]]!.singleWhere((row) => row['id'] == body['supplierId'])['name']! as String,
          value: body['value'] as double,
          isOpenValue: body['isOpenValue'] as bool,
          unitPrice: body['unitPrice'] as double,
          quantity: body['quantity'] as double,
          notes: body['notes'] as String,
        );
      case [final id, 'disable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = false;
      case [final id, 'enable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = true;
      case [final id]:
        final contract = list.singleWhere((row) => row['id'] == id);
        final value = body['value'] as double;
        final isOpenValue = body['isOpenValue'] as bool;
        final paid = contract['paid']! as double;
        contract
          ..['value'] = value
          ..['isOpenValue'] = isOpenValue
          ..['remaining'] = isOpenValue ? 0.0 : value - paid
          ..['isOverrun'] = !isOpenValue && paid > value
          ..['unitPrice'] = body['unitPrice'] as double
          ..['quantity'] = body['quantity'] as double
          ..['notes'] = body['notes'] as String;
    }
    return _json({}, 200);
  }

  /// Adds a category to the project [projectId], as the API holds it.
  Map<String, Object> addCategory(String projectId, String name, {bool isActive = true}) {
    final category = <String, Object>{'id': 'category-${_nextStructureId++}', 'name': name, 'isActive': isActive, 'items': <Map<String, Object>>[]};
    categories.putIfAbsent(projectId, () => []).add(category);
    return category;
  }

  /// Adds an item to [category], as the API holds it, with its general group and any [subgroups].
  Map<String, Object> addItem(Map<String, Object> category, String name, {String type = 'both', bool isActive = true, List<String> subgroups = const []}) {
    final item = <String, Object>{
      'id': 'item-${_nextStructureId++}',
      'name': name,
      'type': type,
      'isActive': isActive,
      'subgroups': <Map<String, Object>>[
        for (final subgroup in ['', ...subgroups]) {'id': 'subgroup-${_nextStructureId++}', 'name': subgroup},
      ],
    };
    (category['items']! as List<Map<String, Object>>).add(item);
    return item;
  }

  http.Response _answerStructure(http.Request request) {
    final segments = request.url.pathSegments;
    final list = categories.putIfAbsent(segments[1], () => []);
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentStructureChanges.add((request.url.path, body));
    if (structureAnswer.status >= 300) {
      return _json({if (structureAnswer.code.isNotEmpty) 'code': structureAnswer.code}, structureAnswer.status);
    }
    final items = [for (final category in list) ...category['items']! as List<Map<String, Object>>];
    final rows = segments[2] == 'categories' ? list : items;
    final row = segments.length > 3 ? rows.where((row) => row['id'] == segments[3]).firstOrNull ?? const <String, Object>{} : const <String, Object>{};
    void reorderBy(List<Map<String, Object>> rows) {
      final order = body['ids'] as List<dynamic>;
      rows.sort((first, second) => order.indexOf(first['id']).compareTo(order.indexOf(second['id'])));
    }

    switch (segments.sublist(2)) {
      case ['categories']:
        addCategory(segments[1], body['name'] as String);
      case ['categories', 'reorder']:
        reorderBy(list);
      case ['categories', _, 'items']:
        addItem(row, body['name'] as String, type: body['type'] as String);
      case ['categories', _, 'items', 'reorder']:
        reorderBy(row['items']! as List<Map<String, Object>>);
      case [_, _, 'disable']:
        row['isActive'] = false;
      case [_, _, 'enable']:
        row['isActive'] = true;
      case ['items', _, 'subgroups']:
        (row['subgroups']! as List<Map<String, Object>>).add({'id': 'subgroup-${_nextStructureId++}', 'name': body['name'] as String});
      case ['items', _, 'subgroups', final subgroupId]:
        (row['subgroups']! as List<Map<String, Object>>).singleWhere((subgroup) => subgroup['id'] == subgroupId)['name'] = body['name'] as String;
      default:
        row['name'] = body['name'] as String;
    }
    return _json({}, 200);
  }

  /// Adds a column at the address [path], as the API holds it.
  Map<String, Object> addColumn(String path, String name, {String dataType = 'text', bool isCore = false, bool isCustom = false, bool isRequired = false, bool showInReports = false}) {
    final column = <String, Object>{
      'id': 'column-${_nextStructureId++}',
      'key': name,
      'name': name,
      'dataType': dataType,
      'isCore': isCore,
      'isCustom': isCustom,
      'isRequired': isRequired,
      'showInReports': showInReports,
      'options': <String>[],
    };
    columns.putIfAbsent(path, () => []).add(column);
    return column;
  }

  http.Response _answerColumns(http.Request request) {
    final path = request.url.path;
    final segments = request.url.pathSegments;
    final columnsEnd = segments[2] == 'default-columns' ? 4 : 5;
    final list = columns.putIfAbsent(segments.take(columnsEnd).map((segment) => '/$segment').join(), () => []);
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentStructureChanges.add((path, body));
    if (structureAnswer.status >= 300) {
      return _json({if (structureAnswer.code.isNotEmpty) 'code': structureAnswer.code}, structureAnswer.status);
    }
    if (path.endsWith('/reorder')) {
      final order = body['ids'] as List<dynamic>;
      list.sort((first, second) => order.indexOf(first['id']).compareTo(order.indexOf(second['id'])));
    } else if (path.endsWith('/delete')) {
      list.removeWhere((column) => column['id'] == segments[columnsEnd]);
    } else if (segments.length == columnsEnd) {
      addColumn(
        segments.take(columnsEnd).map((segment) => '/$segment').join(),
        body['name'] as String,
        dataType: body['dataType'] as String,
        isCustom: true,
        isRequired: body['isRequired'] as bool,
        showInReports: body['showInReports'] as bool,
      );
    } else {
      list.singleWhere((column) => column['id'] == segments[columnsEnd])
        ..['name'] = body['name'] as String
        ..['isRequired'] = body['isRequired'] as bool
        ..['showInReports'] = body['showInReports'] as bool;
    }
    return _json({}, 200);
  }

  /// Adds a user to what the API holds.
  Map<String, Object> addUser(String displayName, {required String username, String mobile = '', bool isActive = true}) {
    final user = <String, Object>{
      'id': 'user-${users.length}',
      'username': username,
      'displayName': displayName,
      'mobile': mobile,
      'isActive': isActive,
      'mustChangePassword': false,
      'projects': <Map<String, Object>>[],
    };
    users.add(user);
    return user;
  }

  /// Gives [user], as [addUser] answered them, a role in the project [projectId].
  void giveRole(Map<String, Object> user, String projectId, String roleId) {
    final project = projects.singleWhere((project) => project['id'] == projectId);
    final role = roles.singleWhere((role) => role['id'] == roleId);
    (user['projects'] as List<Map<String, Object>>).add({'projectId': projectId, 'name': project['name'] as String, 'role': role});
  }

  /// [user] as a project's list answers them: only that project's lines.
  Map<String, Object> _inProject(Map<String, Object> user, String projectId) => {
    ...user,
    'projects': (user['projects'] as List<Map<String, Object>>).where((line) => line['projectId'] == projectId).toList(),
  };

  http.Response _answerProjectUsers(http.Request request, String projectId) {
    final segments = request.url.pathSegments;
    if (request.method == 'GET') {
      final inProject = users.where((user) => (_inProject(user, projectId)['projects'] as List<Map<String, Object>>).isNotEmpty);
      return _json([for (final user in inProject) _inProject(user, projectId)], 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentUserChanges.add((request.url.path, body));
    if (userAnswer.status >= 300) {
      return _json({if (userAnswer.code.isNotEmpty) 'code': userAnswer.code}, userAnswer.status);
    }
    if (segments.length == 3) {
      final user = addUser(body['displayName'] as String, username: body['username'] as String, mobile: body['mobile'] as String);
      giveRole(user, projectId, roles.last['id']!);
      return _json(_inProject(user, projectId), 201);
    }
    if (segments[3] == 'existing') {
      final user = users.singleWhere((user) => user['username'] == body['username']);
      giveRole(user, projectId, roles.last['id']!);
      return _json(_inProject(user, projectId), 200);
    }
    final user = users.singleWhere((user) => user['id'] == segments[3]);
    if (segments.last == 'remove') {
      (user['projects'] as List<Map<String, Object>>).removeWhere((line) => line['projectId'] == projectId && (line['role']! as Map<String, String>)['id'] == segments[5]);
    } else {
      giveRole(user, projectId, segments[5]);
    }
    return _json(_inProject(user, projectId), 200);
  }

  http.Response _answerUsers(http.Request request) {
    if (request.method == 'GET') {
      return _json(users, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final path = request.url.path;
    sentUserChanges.add((path, body));
    if (userAnswer.status >= 300) {
      return _json({if (userAnswer.code.isNotEmpty) 'code': userAnswer.code}, userAnswer.status);
    }
    final segments = request.url.pathSegments;
    final user = users.singleWhere((user) => user['id'] == segments[1]);
    if (path.endsWith('/disable')) {
      user['isActive'] = false;
    } else if (path.endsWith('/enable')) {
      user['isActive'] = true;
    } else if (!path.endsWith('/reset-password')) {
      user['displayName'] = body['displayName'] as String;
      user['mobile'] = body['mobile'] as String;
    }
    return _json(user, 200);
  }

  /// Answers as bytes with no character set, as a JSON reply may arrive, so reading Arabic takes UTF-8 on the app's side.
  http.Response _json(Object body, int status) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

  /// Adds a project waiting for the admin.
  void addRegistered(String name, {String managerName = 'ريم', String managerUsername = 'reem', String managerMobile = '0500000000', List<String> units = const ['الفلة الغربية']}) {
    registered.add({
      'id': 'registered-${registered.length}',
      'name': name,
      'startDate': '2026-11-05',
      'units': units,
      'managerName': managerName,
      'managerUsername': managerUsername,
      'managerMobile': managerMobile,
    });
  }

  http.Response _answerRegistration(http.Request request) {
    final path = request.url.path;
    if (request.method == 'GET') {
      return _json(registered, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    sentRegistrations.add((path, body));
    if (registrationAnswer.status >= 300) {
      return _json({if (registrationAnswer.code.isNotEmpty) 'code': registrationAnswer.code}, registrationAnswer.status);
    }
    if (path != '/projects/register') {
      registered.removeWhere((project) => project['id'] == request.url.pathSegments[1]);
    }
    return _json({}, path == '/projects/register' ? 201 : 200);
  }

  http.Response _answerDefault(http.Request request) {
    final segments = request.url.pathSegments;
    sentProjectChanges.add((request.url.path, jsonDecode(request.body) as Map<String, dynamic>));
    if (projectAnswer.status >= 300) {
      return _json({if (projectAnswer.code.isNotEmpty) 'code': projectAnswer.code}, projectAnswer.status);
    }
    final removing = segments.last == 'remove';
    defaultProjectId = removing ? '' : segments[1];
    openDefaultProject = !removing && (jsonDecode(request.body) as Map<String, dynamic>)['openDirectly'] as bool;
    return _json({'defaultProjectId': defaultProjectId, 'openDefaultProject': openDefaultProject}, 200);
  }

  FutureOr<http.Response> _answerProjects(http.Request request) {
    final segments = request.url.pathSegments;
    if (segments.last == 'default' || segments.length == 3 && segments[1] == 'default') {
      return _answerDefault(request);
    }
    if (segments.length == 2 && (segments[1] == 'register' || segments[1] == 'registered') || segments.length == 3 && (segments[2] == 'approve' || segments[2] == 'reject')) {
      return _answerRegistration(request);
    }
    if (segments.length >= 3 && segments[2] == 'roles') {
      return _json(roles, 200);
    }
    if (segments.length >= 3 && segments[2] == 'users') {
      return _answerProjectUsers(request, segments[1]);
    }
    if (segments.length >= 3 && (segments[2] == 'default-columns' || segments.length >= 5 && segments[4] == 'columns')) {
      return _answerColumns(request);
    }
    if (segments.length >= 3 && (segments[2] == 'categories' || segments[2] == 'items')) {
      return _answerStructure(request);
    }
    if (segments.length >= 3 && segments[2] == 'payment-methods') {
      return _answerPaymentMethods(request);
    }
    if (segments.length >= 3 && segments[2] == 'accounts') {
      return _answerAccounts(request);
    }
    if (segments.length >= 3 && segments[2] == 'partners') {
      return _answerPartners(request);
    }
    if (segments.length == 4 && segments[2] == 'suppliers' && segments[3] == 'search') {
      return _searchSuppliers(request);
    }
    if (segments.length >= 3 && segments[2] == 'suppliers') {
      return _answerSuppliers(request);
    }
    if (segments.length >= 3 && segments[2] == 'contracts') {
      return _answerContracts(request);
    }
    if (segments.length >= 3 && segments[2] == 'expenses') {
      sentExpenses.add(jsonDecode(request.body) as Map<String, dynamic>);
      return _json(expenseAnswer.body, expenseAnswer.status);
    }
    if (segments.length >= 3 && segments[2] == 'attachments') {
      sentAttachments.add(latin1.decode(request.bodyBytes));
      if (attachmentAnswer.status >= 300) {
        return _json({if (attachmentAnswer.code.isNotEmpty) 'code': attachmentAnswer.code}, attachmentAnswer.status);
      }
      return _json({'id': 'attachment-${_nextStructureId++}', 'fileName': RegExp('filename="([^"]*)"').firstMatch(latin1.decode(request.bodyBytes))!.group(1)!}, attachmentAnswer.status);
    }
    if (segments.length >= 3 && segments[2] == 'members') {
      return _json(members, 200);
    }
    if (request.method == 'GET') {
      return _json(projects, 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final path = request.url.path;
    sentProjectChanges.add((path, body));
    if (projectAnswer.status >= 300) {
      return _json({if (projectAnswer.code.isNotEmpty) 'code': projectAnswer.code}, projectAnswer.status);
    }
    if (path == '/projects') {
      return _json(addProject(body['name'] as String, startDate: body['startDate'] as String, units: (body['units'] as List<dynamic>).cast<String>()), 201);
    }
    final project = projects.singleWhere((project) => project['id'] == request.url.pathSegments[1]);
    if (path.endsWith('/close')) {
      project['status'] = 'finished';
    } else if (path.endsWith('/vat-rate')) {
      project['vatPercent'] = body['vatPercent'] as double;
    } else {
      final units = project['units'] as List<Map<String, String>>;
      final unit = {'id': '${project['id']}-unit-${units.length}', 'name': body['name'] as String};
      units.add(unit);
      (project['entryUnits']! as List<Map<String, String>>).insert(units.length - 1, unit);
    }
    return _json(project, 200);
  }
}

/// The words of [language] as the phone keeps them after an earlier start.
Map<String, Object> keptWords(String language) => {'words': jsonEncode({'language': language, 'etag': '"1"', 'words': wordsIn(language)})};

/// Starts the app on a phone in [locale], with [stored] in its secure storage and [preferences] kept, talking to [api].
Future<Session> pumpRedix(
  WidgetTester tester,
  FakeApi api, {
  Locale locale = const Locale('en'),
  Map<String, String> stored = const {},
  Map<String, Object> preferences = const {},
  FakePrompt? prompt,
  InvoiceCapture? capture,
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  FlutterSecureStorage.setMockInitialValues(Map.of(stored));
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final session = Session(const FlutterSecureStorage(), Biometrics(prompt ?? FakePrompt()));
  final language = AppLanguage();
  await http.runWithClient(() async {
    await session.restore();
    await language.restore();
    await tester.pumpWidget(RedixApp(session: session, language: language, capture: capture ?? FakeCapture()));
    await tester.pumpAndSettle();
  }, () => api.client);
  return session;
}

/// Runs [action] and lets the app settle, with the app's requests reaching [api].
Future<void> act(WidgetTester tester, FakeApi api, Future<void> Function() action) => http.runWithClient(() async {
  await action();
  await tester.pumpAndSettle();
}, () => api.client);
