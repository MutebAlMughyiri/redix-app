import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:go_router/go_router.dart';
import 'package:redix/projects/project_settings_card.dart';
import 'package:redix/offline/local_store.dart';
import 'package:redix/attachments/invoice_capture.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/biometrics.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/main.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/search_line.dart';
import 'package:redix/ui/search_scope.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/ui/arabic_spelling.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/words/app_language.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redix/config/local_config.dart';

/// The words the fake API serves: each key's value names its language and key, so a test reads which word is shown.
Map<String, String> wordsIn(String language) => {
  for (final key in [
    'app.title',
    'entries.share', 'entries.notFound', 'approvals.showAll', 'entryShare.item', 'entryShare.partner', 'entryShare.supplier', 'entryShare.contractor', 'entryShare.amount',
    'entryShare.date', 'entryShare.status', 'entryShare.account', 'entryShare.paymentMethod', 'entryShare.author', 'entryShare.notes',
    'biometrics.signIn', 'biometrics.hint', 'biometrics.or', 'biometrics.failed', 'biometrics.usePassword', 'biometrics.promptTitle', 'biometrics.promptCancel', 'biometrics.notAvailable', 'biometrics.notChanged',
    'projects.choose', 'projects.chooseHint', 'projects.defaultProject', 'projects.defaultSet', 'sharedSettings.defaultProject', 'sharedSettings.defaultProjectHint', 'sharedSettings.switchProject',
    'sharedSettings.appearance', 'sharedSettings.themeSystem', 'sharedSettings.themeLight', 'sharedSettings.themeDark', 'sharedSettings.entriesShown', 'sharedSettings.entriesShownHint',
    'signIn.username', 'signIn.password', 'signIn.hint', 'signIn.submit', 'signIn.forgotPassword',
    'signIn.invalidCredentials', 'signIn.accountLocked', 'signIn.sessionExpired', 'signIn.noConnection', 'signIn.refused',
    'changePassword.title', 'changePassword.hint', 'changePassword.current', 'changePassword.new', 'changePassword.confirm',
    'changePassword.submit', 'changePassword.mismatch', 'changePassword.invalidCredentials', 'changePassword.accountLocked',
    'changePassword.weakPassword', 'changePassword.noConnection', 'changePassword.refused',
    'myAccount.language', 'myAccount.arabic', 'myAccount.english', 'myAccount.languageNeedsNetwork',
    'permissions.title', 'permissions.hint', 'permissions.count', 'permissions.mine', 'permissions.mineHint', 'projects.importSettings', 'projects.exportSettings', 'common.passwordRules',
    'permissions.readProject', 'permissions.readProjectHint', 'permissions.manageUsers', 'permissions.manageUsersHint', 'permissions.seeAllCapital', 'permissions.seeAllCapitalHint', 'permissions.seeChosenCapital', 'permissions.seeChosenCapitalHint', 'permissions.capitalGroup', 'permissions.manageProject', 'permissions.manageProjectHint', 'permissions.manageStructure', 'permissions.manageStructureHint', 'permissions.manageSettings', 'permissions.manageSettingsHint', 'permissions.addSupplier', 'permissions.addSupplierHint', 'permissions.chargeAnyAccount', 'permissions.chargeAnyAccountHint', 'permissions.recordEntries', 'permissions.recordEntriesHint', 'permissions.manageAnyEntry', 'permissions.manageAnyEntryHint', 'permissions.deleteEntries', 'permissions.deleteEntriesHint', 'permissions.removeApprovedEntries', 'permissions.removeApprovedEntriesHint', 'permissions.attachFiles', 'permissions.attachFilesHint', 'permissions.approveEntries', 'permissions.approveEntriesHint', 'permissions.moveMoney', 'permissions.moveMoneyHint',
    'users.addExisting', 'users.unknownUser', 'users.invalidPermission', 'users.lastManager', 'users.unknownPartner', 'users.otherProject',
    'signIn.registerProject', 'register.hint', 'register.sent', 'register.tooManyTries', 'register.invalidName', 'register.invalidUsername',
    'register.invalidMobile', 'register.unitNameTaken', 'projects.unitNameTaken', 'register.weakPassword', 'register.usernameTaken', 'register.noConnection', 'register.refused',
    'projects.pending', 'projects.rejected', 'registered.title', 'registered.empty', 'registered.loadFailed', 'registered.approve', 'registered.reject',
    'registered.reason', 'registered.invalidReason', 'registered.notPending', 'registered.noConnection', 'registered.refused',
    'myAccount.changePassword', 'myAccount.signOut', 'myAccount.signOutQuestion', 'myAccount.signOutExplain',
    'sharedSettings.title', 'projects.new', 'projects.manager', 'projects.empty', 'projects.loadFailed', 'common.retry', 'projects.active',
    'projects.finished', 'projects.readOnly', 'projects.inactive', 'projects.startDate', 'projects.name', 'projects.units', 'projects.noUnits',
    'projects.unitName', 'projects.addUnit', 'projects.create', 'common.cancel', 'projects.close',
    'projects.closeQuestion', 'projects.closeExplain', 'projects.pendingEntries', 'projects.rename', 'projects.renameUnit', 'projects.save', 'projects.invalidName', 'projects.projectFinished', 'projects.noConnection',
    'projects.refused', 'projects.description', 'projects.invalidDescription', 'register.invalidDescription', 'projectInfo.title', 'projectInfo.description',
    'projectInfo.descriptionHint', 'projectInfo.noDescription', 'projectInfo.save', 'projectInfo.saved',
    'users.title', 'users.noMatch', 'users.new', 'users.loadFailed', 'users.disabled', 'users.edit', 'users.resetPassword', 'users.disable',
    'users.enable', 'users.name', 'users.nameHint', 'users.username', 'users.mobile', 'users.temporaryPassword',
    'users.temporaryPasswordHint', 'users.add', 'users.save', 'users.disableQuestion', 'users.disableExplain', 'users.resetExplain',
    'users.invalidName', 'users.invalidUsername', 'users.invalidMobile', 'users.usernameTaken', 'users.weakPassword',
    'users.noConnection', 'users.refused',
    'columns.title', 'columns.template', 'columns.thisItem', 'columns.hint', 'columns.empty', 'columns.loadFailed', 'columns.noConnection', 'columns.refused', 'columns.projectFinished',
    'columns.invalidName', 'columns.invalidOrder', 'columns.invalidDataType', 'columns.invalidOptions', 'columns.coreColumn', 'columns.new', 'columns.name', 'columns.type', 'columns.typeText',
    'columns.typeNumber', 'columns.typeAmount', 'columns.typeDate', 'columns.typeList', 'columns.typeFile', 'columns.choices', 'columns.newChoices', 'columns.required', 'columns.optional', 'columns.showInReports',
    'columns.inReports', 'columns.custom', 'columns.core', 'columns.edit', 'columns.save', 'columns.applyQuestion', 'columns.applyExplain',
    'columns.applyToAll', 'columns.templateOnly',
    'home.hideDetails', 'home.showDetails',
    'entries.title', 'entries.mine', 'entries.showMore', 'entries.kind', 'entries.status', 'common.searchIn', 'common.search', 'common.filter', 'entries.empty', 'entries.new', 'entries.table', 'entries.tableSearchHint', 'entries.noTableMatch', 'entries.search', 'entries.searchHint', 'entries.purchases', 'entries.contractorPayments', 'entries.period', 'entries.clearFilters', 'entries.enteredBy', 'entries.loadFailed', 'entries.noConnection', 'entries.refused', 'entries.draft', 'entries.pendingApproval', 'entries.approved', 'entries.rejected', 'entries.reason', 'entries.fix', 'entries.edit', 'entries.send', 'entries.remove', 'entries.entryApproved', 'entries.entryWaitingForDecision', 'entries.notYourEntry', 'entries.reasonRequired', 'entries.entryIncomplete', 'entries.entryNotSubmittable', 'expenses.entryApproved', 'expenses.entryWaitingForDecision', 'expenses.notYourEntry', 'expenses.reasonRequired', 'reports.title', 'reports.periodic', 'reports.lastIssued', 'reports.noneIssued', 'reports.issue', 'reports.issueQuestion', 'reports.issueExplain', 'reports.issued', 'reports.reportNumber', 'reports.pdf', 'reports.excel', 'reports.print', 'reports.share', 'reports.earlier', 'reports.fileFailed', 'reports.previous', 'reports.current', 'reports.difference', 'reports.revenueAndExpenses', 'reports.contracts', 'reports.partners', 'reports.chooseItem', 'reports.loadFailed', 'reports.noConnection', 'reports.refused', 'reports.itemTotal', 'reports.generalSubgroup', 'reports.number', 'reports.description', 'reports.invoiceNumber', 'reports.date', 'reports.unitPrice', 'reports.quantity', 'reports.cost', 'reports.contractValue', 'reports.openValue', 'reports.paid', 'reports.remaining', 'reports.overrun', 'reports.outsideContract', 'reports.grandTotal', 'reports.noContracts', 'reports.pendingExpenses', 'reports.pendingRevenue', 'summary.pending', 'summary.pendingHint', 'summary.surplus', 'summary.surplusWithoutSales', 'summary.revenue', 'summary.expenses', 'summary.difference', 'summary.byCategory', 'summary.completion', 'summary.loadFailed', 'revenue.title', 'revenue.unknownItem', 'revenue.vatRefund', 'revenue.sale', 'revenue.date', 'revenue.amount', 'revenue.account', 'revenue.description', 'revenue.file', 'revenue.loadFailed', 'revenue.noConnection', 'revenue.refused', 'revenue.invalidDate', 'revenue.invalidAmount', 'revenue.invalidNotes', 'revenue.unknownAccount', 'revenue.unknownAttachment', 'revenue.invoiceAlreadyAttached', 'vat.title', 'vat.quarter', 'vat.halfYear', 'vat.custom', 'vat.q1', 'vat.q2', 'vat.q3', 'vat.q4', 'vat.h1', 'vat.h2', 'vat.from', 'vat.to', 'accounts.reconcile', 'reconciliations.title', 'reconciliations.surplus', 'reconciliations.actualTotal', 'reconciliations.difference', 'reconciliations.differenceExplain', 'reconciliations.lastUpdated', 'reconciliations.never', 'reconciliations.enterTitle', 'reconciliations.books', 'reconciliations.save', 'reconciliations.loadFailed', 'reconciliations.noConnection', 'reconciliations.refused', 'reconciliations.unknownAccount', 'reconciliations.invalidAmount', 'reconciliations.accountMissing', 'capital.total', 'capital.balance', 'capital.share', 'capital.movements', 'capital.noMovements', 'capital.partner', 'capital.type', 'capital.contribution', 'capital.withdrawal', 'capital.amount', 'capital.date', 'capital.account', 'capital.description', 'capital.receipt', 'capital.receiptRequiredWord', 'capital.receiptHint', 'capital.receiptAmount', 'capital.receiptDiffers', 'capital.paidInCash', 'capital.cashReason', 'capital.save', 'capital.cash', 'capital.receiptAttached', 'capital.loadFailed', 'capital.noConnection', 'capital.refused', 'capital.receiptRequired', 'capital.invalidReason', 'capital.unknownPartner', 'capital.invalidDate', 'capital.invalidAmount', 'capital.invalidNotes', 'capital.unknownAccount', 'capital.unknownAttachment', 'capital.invoiceAlreadyAttached', 'entries.tiedProjectRefused', 'share.title', 'share.project', 'share.noProject', 'share.chooseItem', 'share.empty', 'share.expense', 'share.matching', 'share.attach', 'share.newExpense', 'share.attached', 'share.amountDiffers', 'share.supplierDiffers', 'share.loadFailed', 'share.noConnection', 'share.refused', 'share.notYourEntry', 'share.entryNotAttachable', 'share.unknownAttachment', 'share.invoiceAlreadyAttached', 'notifications.title', 'notifications.empty', 'notifications.loadFailed', 'notifications.noConnection', 'notifications.refused', 'notifications.entrySubmitted', 'notifications.entryApproved', 'notifications.entryRejected', 'notifications.projectApproved', 'notifications.projectRejected', 'approvals.title', 'approvals.empty', 'approvals.loadFailed', 'approvals.noConnection', 'approvals.all', 'approvals.purchases', 'approvals.contractorPayments', 'approvals.approve', 'approvals.reject', 'approvals.approveSelected', 'approvals.selectHint', 'approvals.enteredBy', 'approvals.openFile', 'approvals.fileFailed', 'approvals.rejectTitle', 'approvals.quickReason', 'approvals.reasonUnclear', 'approvals.reasonAmount', 'approvals.reasonItem', 'approvals.reasonDuplicate', 'approvals.reason', 'approvals.reasonHint', 'approvals.rejectSend', 'approvals.reasonRequired', 'approvals.entryNotPending', 'approvals.unknownEntry', 'approvals.refused', 'approvals.approvedSome', 'approvals.failedSome',
    'expenses.keptOnPhone', 'offline.title', 'offline.empty', 'offline.autoSend', 'offline.sendNow', 'offline.withFile', 'offline.sendAgain',
    'categories.title', 'categories.hint', 'categories.empty', 'categories.loadFailed', 'categories.noConnection', 'categories.refused', 'categories.projectFinished',
    'categories.invalidName', 'categories.invalidOrder', 'categories.generalSubgroup', 'categories.subgroupInUse', 'categories.itemHasEntries', 'categories.itemTakesNoPurchases', 'categories.changeType', 'categories.tablePercentages', 'categories.tables', 'categories.tablesHint', 'categories.tablePurchases', 'categories.tableRevenue', 'categories.tableContract', 'categories.tableCapital', 'entries.withdrawal', 'entries.withdrawalHint', 'swipe.remove', 'swipe.question', 'swipe.removed', 'common.undo', 'entries.removeQuestion', 'entries.view', 'entries.approvedCannotChange', 'entries.notYours', 'documents.download', 'entries.capitalGroup', 'categories.side', 'categories.sideExpenses', 'categories.sideRevenue', 'categories.typeSale', 'categories.typeVatRefund', 'categories.typeOtherRevenue', 'columns.revenueTakesNoColumns', 'categories.new', 'categories.categoryName', 'categories.items', 'categories.noItems',
    'categories.addItem', 'categories.itemName', 'categories.itemType', 'categories.typePurchases', 'categories.typeContractorPayments', 'categories.typeBoth', 'categories.rename',
    'categories.disable', 'categories.enable', 'categories.disabled', 'categories.save',
    'subgroups.new', 'categories.subgroupName', 'projects.structureSource', 'projects.defaultTemplate', 'projects.unknownSource',
    'paymentMethods.title', 'paymentMethods.empty', 'paymentMethods.loadFailed', 'paymentMethods.noConnection', 'paymentMethods.refused', 'paymentMethods.projectFinished',
    'paymentMethods.invalidName', 'paymentMethods.new', 'paymentMethods.name', 'paymentMethods.rename', 'paymentMethods.save', 'paymentMethods.disable', 'paymentMethods.enable', 'paymentMethods.disabled', 'paymentMethods.paymentMethodUsed',
    'accounts.title', 'accounts.empty', 'accounts.loadFailed', 'accounts.noConnection', 'accounts.refused', 'accounts.projectFinished', 'accounts.invalidName', 'accounts.custodianRequired', 'accounts.unknownCustodian', 'accounts.new', 'accounts.edit', 'accounts.save', 'accounts.type', 'accounts.typeBank', 'accounts.typeCashCustody', 'accounts.name',
    'partners.title', 'partners.empty', 'partners.loadFailed', 'partners.noConnection', 'partners.refused', 'partners.projectFinished', 'partners.invalidName', 'partners.unknownUser', 'partners.userTaken', 'partners.itemNotOffered',
    'partners.new', 'partners.edit', 'partners.save', 'partners.name', 'partners.history', 'partners.delete', 'partners.deleteQuestion', 'partners.deleteKeepsMovements', 'partners.deleted', 'partners.partnerNotDeletable', 'partners.deleteRemovesMyDrafts', 'partners.myDraftsNeedDeleteEntries', 'partners.login', 'partners.noLogin', 'partners.loginHint',
    'suppliers.title', 'suppliers.empty', 'suppliers.loadFailed', 'suppliers.noConnection', 'suppliers.refused', 'suppliers.projectFinished', 'suppliers.invalidName', 'suppliers.invalidVatNumber',
    'suppliers.invalidMobile', 'suppliers.generalCashSupplier', 'suppliers.vatNumberTaken', 'suppliers.holder', 'suppliers.unknownItem', 'suppliers.new', 'suppliers.edit', 'suppliers.save', 'suppliers.name', 'suppliers.vatNumber',
    'suppliers.mobile', 'suppliers.defaultItem', 'suppliers.noDefaultItem', 'suppliers.pendingApproval', 'suppliers.disable', 'suppliers.enable', 'suppliers.disabled',
    'suppliers.pick', 'suppliers.searchHint', 'suppliers.noMatch', 'categories.noTableMatch', 'suppliers.quickAdd', 'suppliers.addAndPick', 'suppliers.pendingHint', 'suppliers.useExisting',
    'contracts.title', 'contracts.empty', 'contracts.loadFailed', 'contracts.noConnection', 'contracts.refused', 'contracts.projectFinished', 'contracts.unknownSupplier', 'contracts.itemNotOffered',
    'contracts.contractHasPayments', 'contracts.invalidValue', 'contracts.invalidUnitPrice', 'contracts.invalidQuantity', 'contracts.invalidNotes', 'contracts.new', 'contracts.edit', 'contracts.save',
    'contracts.contractor', 'contracts.item', 'contracts.openValue', 'contracts.contractValue', 'contracts.unitPrice', 'contracts.quantity', 'contracts.notes', 'contracts.value',
    'contracts.paid', 'contracts.remaining', 'contracts.open', 'contracts.overrun', 'contracts.notStarted', 'contracts.running', 'contracts.filterAll', 'contracts.filterOverrun',
    'contracts.filterOpenValue', 'contracts.disable', 'contracts.enable', 'contracts.disabled', 'contracts.documents', 'contracts.addDocument', 'contracts.unknownAttachment',
    'attachments.invalidFileType', 'attachments.imageTooLarge', 'attachments.projectFinished', 'attachments.noConnection', 'attachments.refused', 'attachments.cameraFailed', 'attachments.unreadable', 'attachments.fileEmpty',
    'attachments.invoicePhoto', 'attachments.retake', 'attachments.takePhoto', 'attachments.pickFile',
    'expenses.item', 'expenses.supplier', 'expenses.date', 'expenses.product', 'expenses.unitPrice', 'expenses.quantity',
    'expenses.total',
    'expenses.paymentMethod', 'expenses.account', 'expenses.noAccount', 'expenses.notes',
    'expenses.send', 'expenses.saveDraft', 'expenses.sent', 'expenses.saved', 'expenses.noConnection', 'expenses.refused', 'expenses.projectFinished', 'expenses.invalidEntryId',
    'expenses.entryExists', 'expenses.itemNotOffered', 'expenses.unknownSubgroup', 'expenses.unknownSupplier', 'expenses.unknownPaymentMethod', 'expenses.accountNotOffered', 'expenses.unknownAttachment',
    'expenses.invalidProduct', 'expenses.invalidNotes', 'expenses.invalidUnitPrice', 'expenses.invalidQuantity', 'expenses.invalidAmount',
    'expenses.invalidPaymentDate', 'expenses.unknownColumn', 'expenses.invalidColumnValue', 'expenses.requiredColumnMissing', 'expenses.qrRead',
    'expenses.qrUnreadable', 'expenses.qrSupplierMissing', 'expenses.qrAddSupplier', 'suppliers.mostUsed',
    'expenses.duplicateTitle', 'expenses.duplicateExplain', 'expenses.invoiceAlreadyAttached',
    'expenses.amount',     'expenses.unknownContract', 'contracts.pending', 'contracts.afterApproval', 'contractorPayments.remainingAfter',
    'contractorPayments.overrun', 'contractorPayments.savedOverrun', 'contractorPayments.kind', 'contractorPayments.inside', 'contractorPayments.outside', 'contractorPayments.outsideExplain',
    'contractorPayments.receipt',
    'documents.title', 'documents.none', 'documents.add', 'documents.name', 'documents.group', 'documents.groupHint', 'documents.file', 'documents.fileHint', 'documents.save', 'documents.saved', 'documents.loadFailed', 'documents.noConnection', 'documents.refused', 'documents.projectFinished', 'documents.invalidName', 'documents.invalidGroup', 'documents.fileRequired', 'documents.fileTooLarge', 'documents.documentAlreadyKept',
                'capital.pendingEntries',     'reports.save', 'reports.downloaded',
    'reports.surplus',
    'expenses.creditNote', 'expenses.creditNoteExplain', 'expenses.loadFailed',
    'expenses.deductionNeedsNotes', 'revenue.total', 'accounts.custodian', 'accounts.noCustodian', 'accounts.disable', 'accounts.enable', 'accounts.disabled', 'accounts.myCustody', 'accounts.counted', 'accounts.history', 'accounts.delete', 'accounts.deleteQuestion', 'accounts.deleteCannotUndo', 'accounts.accountInUse', 'accounts.deleted', 'accounts.banks', 'accounts.custodies', 'transfers.title', 'transfers.button', 'transfers.from', 'transfers.to', 'transfers.balanceNow', 'transfers.amount', 'transfers.date', 'transfers.notes', 'transfers.save', 'transfers.sameAccount', 'transfers.invalidAmount', 'transfers.accountDisabled', 'transfers.insufficientBalance', 'transfers.unknownAccount', 'transfers.invalidNotes', 'transfers.noConnection', 'transfers.refused', 'transfers.projectFinished', 'approvals.accountShort', 'entryShare.accountShort', 'history.account', 'history.partner', 'history.all', 'history.partnerCreated', 'history.partnerChanged', 'history.partnerAccount', 'history.partnerDeleted', 'history.capitalIn', 'history.capitalOut', 'history.mine', 'history.empty', 'history.loadFailed', 'history.unknownAccount', 'history.accountCreated', 'history.accountChanged', 'history.nameWas', 'history.accountDisabled', 'history.accountEnabled', 'history.accountDeleted', 'history.custodianChanged', 'history.transfer', 'history.entryIn', 'history.entryOut', 'history.check', 'history.approvedBy', 'history.more', 'history.entryApproved', 'history.entryRejected', 'approvals.history', 'entries.kind', 'accounts.riyal',
  ])
    key: '$language $key',
  'partners.draftsBy': '$language partners.draftsBy {0}',
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
const managerAndFinance = ['manageUsers', 'readProject', 'seeAllCapital', 'manageProject', 'manageStructure', 'manageSettings', 'addSupplier', 'recordEntries', 'deleteEntries', 'attachFiles', 'chargeAnyAccount', 'approveEntries', 'manageAnyEntry', 'moveMoney'];

/// What someone in the field may do in a project.
const field = ['readProject', 'addSupplier', 'recordEntries', 'deleteEntries', 'attachFiles'];

/// What someone who only reads a project may do in it.
const reader = ['readProject'];

/// A picture of one pixel, which a test can draw.
const onePixelPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0, 0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// Report 1 as the API answers it once issued.
Map<String, Object> issuedReport() => {
  'number': 1,
  'issuedAt': '2026-11-05T20:00:00Z',
  'accounts': [
    {'name': 'البنك', 'type': 'bank', 'balance': 900},
  ],
  'accountsTotal': 900,
  'previousExpenses': 100,
  'expenses': 140,
  'expensesDifference': 40,
  'revenueCategories': [
    {'id': 'category-capital', 'name': 'رأس المال', 'total': 1000, 'items': <Map<String, Object>>[]},
  ],
  'revenue': 1000,
  'revenueWithoutSales': 1000,
  'categories': [
    {'id': 'category-1', 'name': 'التشطيب', 'total': 140, 'items': <Map<String, Object>>[]},
  ],
  'surplus': 860,
  'surplusWithoutSales': 860,
  'reconciliationDifference': 40,
  'pendingCount': 0,
  'pendingAmount': 0,
  'pendingRevenueCount': 0,
  'pendingRevenueAmount': 0,
  'capitalTotal': 1000,
  'partners': [
    {'name': 'متعب', 'balance': 1000, 'sharePercent': 100},
  ],
};

/// What waits for approval, as the API answers it: [expensesCount] expenses coming to [expensesAmount], and [revenueCount] revenue entries or partners' movements adding [revenueAmount].
Map<String, Object> waiting({int expensesCount = 0, double expensesAmount = 0, int revenueCount = 0, double revenueAmount = 0}) => {
  'expensesCount': expensesCount,
  'expensesAmount': expensesAmount,
  'revenueCount': revenueCount,
  'revenueAmount': revenueAmount,
};

/// The phone's camera and files, as the app's tests see them: each answers what the test chose, and nothing until it chooses.
class FakeCapture extends InvoiceCapture {
  final _sharedFiles = StreamController<PickedFile>.broadcast();

  /// Shares [file] to the app, as WhatsApp would.
  void share(PickedFile file) => _sharedFiles.add(file);

  /// The files the app sent to the printer, by name.
  final printed = <String>[];

  /// The files the app handed to the share sheet: their name and type.
  final sharedOut = <(String, String)>[];

  @override
  Future<void> printPdf(Uint8List bytes, String name) async => printed.add(name);

  @override
  Future<void> shareFile(Uint8List bytes, String name, String mimeType) async => sharedOut.add((name, mimeType));

  /// The texts the app handed to the share sheet.
  final sharedTexts = <String>[];

  @override
  Future<void> shareText(String text) async => sharedTexts.add(text);

  /// The files the app saved on the phone: their name and type.
  final savedOut = <(String, String)>[];

  @override
  Future<void> saveFile(Uint8List bytes, String name, String mimeType) async => savedOut.add((name, mimeType));

  @override
  Stream<PickedFile> shared() => _sharedFiles.stream;

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

  @override
  Future<PickedFile> fromAnyFile() async => files;
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

/// A phone's kept files, in memory.
class MemoryStore extends LocalStore {
  /// What is kept, by folder and name.
  final kept = <String, Map<String, Object>>{};

  @override
  Future<String> read(String folder, String name) async => kept[folder]?[name] as String? ?? '';

  @override
  Future<void> write(String folder, String name, String text) async => kept.putIfAbsent(folder, () => {})[name] = text;

  @override
  Future<Uint8List> readBytes(String folder, String name) async => kept[folder]?[name] as Uint8List? ?? Uint8List(0);

  @override
  Future<void> writeBytes(String folder, String name, List<int> bytes) async => kept.putIfAbsent(folder, () => {})[name] = Uint8List.fromList(bytes);

  @override
  Future<void> delete(String folder, String name) async => kept[folder]?.remove(name);

  @override
  Future<List<String>> namesIn(String folder) async => kept[folder]?.keys.toList() ?? [];

  @override
  Future<void> clear(String folder) async => kept.remove(folder);
}

/// The API as the app's tests see it: words for any language, and the answers of sign-in, refresh and password change each test chooses.
class FakeApi {
  /// Whether the network is up; when false every request fails like a phone without signal.
  var online = true;

  /// The paths whose every request fails as the network does, like a read that takes longer than the app waits.
  final unreachable = <String>{};

  /// The status and problem code `POST /auth/sign-in` answers; 200 opens a session, and an empty code an empty body.
  var signInAnswer = (status: 200, code: '');

  /// Whether the user's password is temporary: sign-in and refresh report it, and a successful change clears it.
  var mustChangePassword = false;

  /// The status `POST /auth/refresh` answers; 200 renews the session.
  var refreshStatus = 200;

  /// How long an access token lasts, which every session answer says as `accessTokenExpiresAt` (redix-api #126). Zero leaves it out, so a case that is not about
  /// renewing on time leaves no renewal waiting when it ends, which flutter_test refuses.
  var accessTokenLifetime = Duration.zero;

  /// The status and problem code `POST /auth/change-password` answers; 200 changes the password, and an empty code an empty body.
  var changePasswordAnswer = (status: 200, code: '');

  /// What the signed-in user holds everywhere: every session says so.
  var permissions = <String>[];

  /// The project the signed-in user chose to land on, as every session says it; empty when none.
  var defaultProjectId = '';

  /// Whether this phone uses a fingerprint or face, as every session says it.
  var usesBiometrics = false;

  /// What turning a fingerprint or face on or off answers.
  var biometricsStatus = 200;

  /// What was last sent to turn a fingerprint or face on or off.
  final sentBiometrics = <bool>[];

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

  /// Where each file was sent: an entry's file, or a document's.
  final sentAttachmentPaths = <String>[];

  /// The id the API gave each file it kept, in the order they were sent.
  final keptAttachmentIds = <String>[];

  /// The status and problem code the API answers to a file; 2xx keeps it. An empty code sends none.
  var attachmentAnswer = (status: 201, code: '');

  /// The entries the app sent, whatever their table, as their bodies (redix-api #110).
  final sentEntries = <Map<String, dynamic>>[];

  /// The status and answer the API gives an expense; 2xx records it.
  var entryAnswer = (status: 201, body: const <String, dynamic>{});

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

  /// The entries the project holds, newest first.
  final entryRows = <Map<String, Object>>[];

  /// How many of the newest each read of the entries list asked for, 0 for every one (redix-app #105).
  final entryReads = <int>[];

  /// What each read of the entries list asked for besides how many: the search and the filters (redix-app #104).
  final entryQueries = <Map<String, List<String>>>[];

  /// The entries read one at a time, as an opened entry reads itself (findings row 201).
  final entryRowReads = <String>[];

  /// Whether the entry [row] holds to the search [address] asks, as the API's EntrySearch decides.
  static bool _searchKeeps(Map<String, Object> row, Uri address) {
    final query = address.queryParametersAll;
    String one(String name) => query[name]?.single ?? '';
    final kinds = query['kinds'] ?? const [];
    final statuses = query['statuses'] ?? const [];
    final standing = row['status'] as String;
    final date = row['entryDate'] as String;
    return (one('mine') != 'true' || row['isMine'] == true) &&
        (kinds.isEmpty || kinds.contains(row['kind'])) &&
        (statuses.isEmpty || statuses.contains(standing)) &&
        (one('from').isEmpty || date.compareTo(one('from')) >= 0) &&
        (one('to').isEmpty || date.compareTo(one('to')) <= 0) &&
        _holds(address, row['amount']! as num, [row['itemName'], row['partnerName'], row['supplierName'], row['authorName'], row['invoiceNumber']]);
  }

  /// Whether what [address] says was typed is in one of [words] or in [amount], as the API's ArabicSpelling.Holds decides (redix-app #104).
  static bool _holds(Uri address, num amount, List<Object?> words) =>
      sameSpelling([...words, if (amount != 0) searchableAmount(amount.toDouble())].join(' ')).contains(sameSpelling(address.queryParameters['text'] ?? ''));

  /// What each entry holds, read to change it.
  final entryDetails = <String, Object>{};

  /// What was asked of an entry: its id, the action and the body.
  final sentEntryChanges = <(String, String, Map<String, dynamic>)>[];

  /// What a change to an entry answers.
  var entryChangeAnswer = (status: 200, code: '');

  /// While set, a change to an entry waits for this before it answers.
  Completer<void> heldEntryChange = Completer<void>()..complete();

  /// While set, the project's list of entries waits for this before it answers.
  Completer<void> heldEntries = Completer<void>()..complete();

  /// The addresses entries were sent to, in order: `entries`, or `entries/{id}` for a change.
  final sentEntryPaths = <String>[];

  /// Adds an entry to the project, named [id] or else by its place.
  Map<String, Object> addEntry({
    String id = '',
    String kind = 'purchase',
    String status = 'pendingApproval',
    String rejectionReason = '',
    double amount = 1150,
    bool isMine = true,
    String itemName = 'بند اللياسة',
    String partnerName = '',
    String notes = '',
    String accountName = 'حساب المؤسسة',
    String paymentMethodName = '',
    double accountShortBy = 0,
  }) {
    final row = <String, Object>{
      'id': id.isEmpty ? 'entry-${entryRows.length}' : id,
      'kind': kind,
      'status': status,
      'rejectionReason': rejectionReason,
      'entryDate': '2026-11-05',
      'amount': amount,
      'itemName': itemName,
      'supplierName': kind == 'purchase' || kind == 'contractorPayment' ? 'شركة البواني' : '',
      'invoiceNumber': '2617',
      'authorName': 'نواف',
      'isMine': isMine,
      'partnerName': partnerName,
      'notes': notes,
      'accountName': accountName,
      'paymentMethodName': paymentMethodName,
      'accountShortBy': accountShortBy,
    };
    entryRows.insert(0, row);
    return row;
  }

  /// What waits for a decision.
  final pendingEntries = <Map<String, Object>>[];

  /// The entries the app asked to approve, by request.
  final sentApprovals = <List<String>>[];

  /// What the API refuses to approve, by entry, with the code.
  final approvalFailures = <String, String>{};

  /// The rejections the app sent.
  final sentRejections = <(String, String)>[];

  /// Adds an entry waiting for a decision.
  Map<String, Object> addPending({
    String kind = 'purchase',
    double amount = 1150,
    String notes = '',
    String attachmentId = 'attachment-1',
    String contentType = 'image/png',
    String fileName = 'invoice-2617.png',
    String partnerName = '',
    double accountBalance = 5000,
    double accountWaiting = 1150,
    double accountShortBy = 0,
  }) {
    final entry = <String, Object>{
      'id': 'entry-${pendingEntries.length}',
      'kind': kind,
      'entryDate': '2026-11-05',
      'amount': amount,
      'itemName': 'بند اللياسة',
      'supplierName': 'شركة البواني',
      'invoiceNumber': '2617',
      'accountName': 'حساب المؤسسة',
      'notes': notes,
      'attachmentId': attachmentId,
      'contentType': contentType,
      'fileName': fileName,
      'authorName': 'نواف',
      'partnerName': partnerName,
      'accountBalance': accountBalance,
      'accountWaiting': accountWaiting,
      'accountShortBy': accountShortBy,
    };
    pendingEntries.add(entry);
    return entry;
  }

  /// What the summary answers.
  var summaryAnswer = <String, Object>{
    'revenue': 0,
    'expenses': 0,
    'surplus': 0,
    'wasReconciled': false,
    'reconciliationDifference': 0,
    'waiting': waiting(),
    'completionPercent': 0,
    'categories': <Map<String, Object>>[],
    'revenueCategories': <Map<String, Object>>[],
  };

  /// What an item's report answers.
  /// The addresses item reports were read at: an item's, or one contract's (Muteb, 12 Nov 2026).
  final itemReportReads = <String>[];

  var itemReportAnswer = <String, Object>{'itemName': 'البلاط', 'categoryName': 'التشطيب', 'total': 0, 'columns': <String>[], 'subgroups': <Map<String, Object>>[], 'contracts': <Map<String, Object>>[]};

  /// The project's documents, as the API holds them.
  final documentRows = <Map<String, Object>>[];

  /// The document changes sent: the path and the form fields sent, with the file's name as `file`.
  final sentDocuments = <(String, Map<String, String>)>[];

  /// The periodic reports issued, newest first.
  final periodicRows = <Map<String, Object>>[];

  /// What a periodic report answers.
  var periodicAnswer = <String, Object>{};

  /// The files the app asked for, by address.
  final sentFileReads = <String>[];

  /// What the app sent to reconcile the accounts, by path.
  final sentMoney = <(String, Map<String, dynamic>)>[];

  /// What the API answers a reconciliation.
  var moneyAnswer = (status: 200, code: '');

  /// What the accounts hold against the books.
  var reconciliationAnswer = <String, Object>{'at': '0001-01-01T00:00:00', 'surplus': 0, 'actualTotal': 0, 'difference': 0, 'balances': <Map<String, Object>>[]};

  /// The total capital.
  var capitalTotal = 0.0;

  /// Each partner's capital.
  final capitalLines = <Map<String, Object>>[];

  /// Each partner's movements, newest first.
  final movementRows = <Map<String, Object>>[];

  /// Adds a line to the capital.
  void addCapitalLine(String id, double balance, double sharePercent) {
    capitalLines.add({'id': id, 'name': id, 'isMine': false, 'balance': balance, 'sharePercent': sharePercent});
  }

  /// Adds a movement.
  void addMovement({String type = 'contribution', double amount = 100, String attachmentId = '', String cashReason = ''}) {
    movementRows.add({
      'id': 'movement-${movementRows.length}',
      'type': type,
      'date': '2026-11-05',
      'amount': amount,
      'description': 'زاد رصيده',
      'cashReason': cashReason,
      'accountName': 'حساب المؤسسة',
      'attachmentId': attachmentId,
      'contentType': attachmentId.isEmpty ? '' : 'image/png',
      'fileName': attachmentId.isEmpty ? '' : 'receipt.png',
    });
  }

  /// What in an item can take a shared invoice.
  final attachableEntries = <Map<String, Object>>[];

  /// The invoices the app attached: to which entry, and what it sent.
  final sentInvoices = <(String, Map<String, dynamic>)>[];

  /// What the API answers an invoice attached.
  var invoiceAnswer = (status: 200, code: '');

  /// Adds an expense that can take an invoice.
  void addAttachable({required String id, String status = 'pendingApproval', double amount = 1150, String supplierVatNumber = '', bool isMatching = false}) {
    attachableEntries.add({
      'id': id,
      'kind': 'purchase',
      'status': status,
      'entryDate': '2026-10-25',
      'amount': amount,
      'product': 'مواد لياسة',
      'supplierName': 'شركة البواني',
      'supplierVatNumber': supplierVatNumber,
      'isMatching': isMatching,
    });
  }

  /// What the user was told, newest first.
  final notificationRows = <Map<String, Object>>[];

  /// Adds something the user was told.
  void addNotification({String kind = 'entrySubmitted', String entryId = 'entry-0', bool isRead = false}) {
    notificationRows.insert(0, {
      'id': 'notification-${notificationRows.length}',
      'kind': kind,
      'projectId': 'project-0',
      'projectName': 'غصون 6',
      'entryId': entryId,
      'at': '2026-11-05T10:00:00Z',
      'isRead': isRead,
    });
  }

  /// How many times the phone asked what changed.
  var syncs = 0;

  /// What the lists of a project hold now.
  var syncStamp = 'stamp-1';

  /// The lists a sync answers, by address.
  var syncLists = const <String, Object>{};

  /// Who signing in makes the user.
  var userId = 'user-signed-in';

  /// What a change waits on before it is answered, to hold one on its way.
  var holdWrites = Future<void>.value();

  /// The paths the app read, in order.
  final sentReads = <String>[];

  /// Access tokens the API treats as expired, answering 401 with no body.
  final expiredAccessTokens = <String>{};

  /// The access tokens the app sent, in order.
  final sentAccessTokens = <String>[];

  /// The client the app's requests reach.
  late final client = MockClient((request) async {
    final path = request.url.path;
    if (!online || unreachable.contains(path)) {
      throw http.ClientException('offline');
    }
    if (request.method == 'GET') {
      sentReads.add(path);
    } else if (!path.startsWith('/auth')) {
      await holdWrites;
    }
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
    if (path == '/notifications') {
      return _json(notificationRows, 200);
    }
    if (path.startsWith('/notifications/')) {
      notificationRows.singleWhere((row) => row['id'] == request.url.pathSegments[1])['isRead'] = true;
      return _json(const <String, Object>{}, 200);
    }
    if (path == '/auth/sign-out') {
      signOuts++;
      return http.Response('', 204);
    }
    if (path.endsWith('/sync')) {
      syncs++;
      final since = request.url.queryParameters['since'] ?? '';
      return _json({'stamp': syncStamp, 'lists': since == syncStamp ? const <String, Object>{} : syncLists}, 200);
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
    final expiresAt = accessTokenLifetime == Duration.zero ? '' : ', "accessTokenExpiresAt": "${DateTime.now().toUtc().add(accessTokenLifetime).toIso8601String()}"';
    final body = status == 200
        ? '{"accessToken": "new-access", "refreshToken": "new-refresh-${_issued++}"$expiresAt, "mustChangePassword": $mustChangePassword, "permissions": ${jsonEncode(permissions)}, "defaultProjectId": "$defaultProjectId", "usesBiometrics": $usesBiometrics, "userId": "$userId", "username": "muteb", "displayName": "متعب المغيري"}'
        : code.isEmpty
        ? ''
        : '{"code": "$code"}';
    return http.Response.bytes(utf8.encode(body), status);
  });

  /// Adds a project to what the API holds, with [units] named in order.
  Map<String, Object> addProject(
    String name, {
    String status = 'active',
    String startDate = '2026-03-01',
    List<String> units = const [],
    String rejectionReason = '',
    String description = '',
    String roleName = '',
    List<String> permissions = managerAndFinance,
  }) {
    final id = 'project-${projects.length}';
    final project = <String, Object>{
      'id': id,
      'name': name,
      'startDate': startDate,
      'status': status,
      'rejectionReason': rejectionReason,
      'description': description,
      'roleName': roleName,
      'isInactive': false,
      'units': [for (final (index, unit) in units.indexed) {'id': '$id-unit-$index', 'name': unit}],
      'permissions': permissions,
    };
    projects.add(project);
    return project;
  }

  /// Makes the signed-in user inactive in [project], as [addProject] answered it, as its manager's «تعطيل» does: the list says so, and holds none of his permissions there
  /// (redix-api #126).
  void makeInactive(Map<String, Object> project) => project
    ..['isInactive'] = true
    ..['permissions'] = <String>[];

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
    final body = _bodyOf(request);
    sentSettingsChanges.add((_written(request), body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    switch (segments.sublist(3)) {
      case []:
        addPaymentMethod(segments[1], body['name'] as String);
      case [final id] when request.method == 'DELETE':
        list.removeWhere((row) => row['id'] == id);
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

  /// Adds an account to the project [projectId], as the API holds it, holding [balance]: what its entries and transfers moved (redix-app #89).
  Map<String, Object> addAccount(
    String projectId,
    String name, {
    String type = 'bank',
    double balance = 0,
    String custodianId = '',
    String custodianName = '',
    bool isMine = false,
    bool isActive = true,
    bool isUsed = false,
  }) {
    final account = <String, Object>{
      'id': 'account-${_nextStructureId++}',
      'type': type,
      'name': name,
      'balance': balance,
      'custodianId': custodianId,
      'custodianName': custodianName,
      'isMine': isMine,
      'isActive': isActive,
      'isUsed': isUsed,
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
    final body = _bodyOf(request);
    sentSettingsChanges.add((_written(request), body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    final custodianId = body['custodianId'] as String? ?? '';
    switch (segments.sublist(3)) {
      case []:
        addAccount(segments[1], body['name'] as String, type: body['type'] as String, custodianId: custodianId, custodianName: _memberName(custodianId));
      case [final id, 'disable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = false;
      case [final id, 'enable']:
        list.singleWhere((row) => row['id'] == id)['isActive'] = true;
      case [final id] when request.method == 'DELETE':
        list.removeWhere((row) => row['id'] == id);
      case [final id]:
        list.singleWhere((row) => row['id'] == id)
          ..['name'] = body['name'] as String
          ..['custodianId'] = custodianId
          ..['custodianName'] = _memberName(custodianId);
    }
    return _json({}, 200);
  }

  /// The transfers the app sent: the project and what it sent.
  final sentTransfers = <(String, Map<String, dynamic>)>[];

  /// Moves a sent transfer's amount between its two accounts at once, as the API does (FR-23), unless [settingsAnswer] refuses it.
  http.Response _answerTransfer(http.Request request) {
    final projectId = request.url.pathSegments[1];
    final body = _bodyOf(request);
    sentTransfers.add((projectId, body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    final list = accounts[projectId]!;
    final amount = (body['amount'] as num).toDouble();
    final from = list.singleWhere((row) => row['id'] == body['fromAccountId']);
    final to = list.singleWhere((row) => row['id'] == body['toAccountId']);
    from['balance'] = (from['balance']! as double) - amount;
    to['balance'] = (to['balance']! as double) + amount;
    from['isUsed'] = true;
    to['isUsed'] = true;
    return _json({}, 200);
  }

  /// The account history of each project, newest first, as the API answers it (redix-app #89).
  final accountHistory = <String, List<Map<String, Object>>>{};

  /// The history addresses the app read, with their filters and page.
  final historyReads = <Uri>[];

  /// Adds a line of [kind] to the history of [projectId], newest first, naming the account [accountId] for the account filter.
  Map<String, Object> addHistoryLine(String projectId, String kind, {String accountId = '', String by = 'متعب', String account = 'حساب المؤسسة', String otherAccount = '', double amount = 0, String entryKind = 'purchase', String nameWas = '', String custodian = ''}) {
    final list = accountHistory.putIfAbsent(projectId, () => []);
    final line = <String, Object>{
      'id': 1000 - list.length,
      'at': '2026-11-10T11:05:00Z',
      'by': by,
      'kind': kind,
      'account': account,
      'otherAccount': otherAccount,
      'amount': amount,
      'entryKind': entryKind,
      'nameWas': nameWas,
      'custodian': custodian,
      'accountId': accountId,
    };
    list.add(line);
    return line;
  }

  http.Response _answerAccountHistory(http.Request request) {
    historyReads.add(request.url);
    final query = request.url.queryParameters;
    final before = int.parse(query['before'] ?? '0');
    final lines = (accountHistory[request.url.pathSegments[1]] ?? const <Map<String, Object>>[])
        .where((line) => before == 0 || (line['id']! as int) < before)
        .where((line) => (query['account'] ?? '').isEmpty || line['accountId'] == query['account'])
        .where((line) => _holds(request.url, line['amount']! as num, [line['by'], line['account'], line['otherAccount'], line['nameWas'], line['custodian']]))
        .take(50)
        .toList();
    return _json(lines, 200);
  }

  /// The partner history of each project, newest first, as the API answers it (redix-app #101).
  final partnerHistory = <String, List<Map<String, Object>>>{};

  /// Adds a line of [kind] to the partner history of [projectId], newest first, naming [partnerId] for the partner filter.
  Map<String, Object> addPartnerHistoryLine(String projectId, String kind, {String partnerId = '', String by = 'متعب', String partner = 'خالد', String account = '', double amount = 0, String nameWas = '', String login = ''}) {
    final list = partnerHistory.putIfAbsent(projectId, () => []);
    final line = <String, Object>{'id': 2000 - list.length, 'at': '2026-11-10T11:05:00Z', 'by': by, 'kind': kind, 'partner': partner, 'account': account, 'amount': amount, 'nameWas': nameWas, 'login': login, 'partnerId': partnerId};
    list.add(line);
    return line;
  }

  http.Response _answerPartnerHistory(http.Request request) {
    historyReads.add(request.url);
    final query = request.url.queryParameters;
    final lines = (partnerHistory[request.url.pathSegments[1]] ?? const <Map<String, Object>>[])
        .where((line) => (query['partner'] ?? '').isEmpty || line['partnerId'] == query['partner'])
        .where((line) => _holds(request.url, line['amount']! as num, [line['by'], line['partner'], line['account'], line['nameWas'], line['login']]))
        .take(50)
        .toList();
    return _json(lines, 200);
  }

  /// The approval history of each project, newest first, as the API answers it (Muteb, 12 Nov 2026).
  final approvalHistory = <String, List<Map<String, Object>>>{};

  /// Adds a decision of [kind], approved or rejected, to the approval history of [projectId], newest first, on an entry of [entryKind] for the kind filter.
  Map<String, Object> addApprovalHistoryLine(String projectId, String kind, {String entryKind = 'purchase', String by = 'متعب', String item = 'البلاط', String party = 'شركة النخيل', double amount = 1150, String reason = ''}) {
    final list = approvalHistory.putIfAbsent(projectId, () => []);
    final line = <String, Object>{'id': 3000 - list.length, 'at': '2026-11-12T09:30:00Z', 'by': by, 'kind': kind, 'item': item, 'party': party, 'amount': amount, 'reason': reason, 'entryKind': entryKind};
    list.add(line);
    return line;
  }

  http.Response _answerApprovalHistory(http.Request request) {
    historyReads.add(request.url);
    final query = request.url.queryParameters;
    final lines = (approvalHistory[request.url.pathSegments[1]] ?? const <Map<String, Object>>[])
        .where((line) => (query['kind'] ?? '').isEmpty || line['entryKind'] == query['kind'])
        .where((line) => _holds(request.url, line['amount']! as num, [line['by'], line['item'], line['party'], line['reason']]))
        .take(50)
        .toList();
    return _json(lines, 200);
  }

  /// Adds a partner to the project [projectId], as the API holds them: a table of the capital item [itemId] (redix-api #109), whose own account is [userId], called [userName]. Who sees
  /// them is chosen on people's permissions (redix-api #106).
  Map<String, Object> addPartner(
    String projectId,
    String name, {
    String userId = '',
    String userName = '',
    String itemId = 'item-capital',
    bool mayDelete = true,
    List<String> othersDrafts = const [],
    List<Map<String, Object>> myDrafts = const [],
  }) {
    final partner = <String, Object>{
      'id': 'partner-${_nextStructureId++}',
      'name': name,
      'userId': userId,
      'userName': userName,
      'itemId': itemId,
      'mayDelete': mayDelete,
      'othersDrafts': othersDrafts,
      'myDrafts': myDrafts,
    };
    partners.putIfAbsent(projectId, () => []).add(partner);
    return partner;
  }

  http.Response _answerPartners(http.Request request) {
    final segments = request.url.pathSegments;
    final list = partners.putIfAbsent(segments[1], () => []);
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = _bodyOf(request);
    sentSettingsChanges.add((_written(request), body));
    if (settingsAnswer.status >= 300) {
      return _json({if (settingsAnswer.code.isNotEmpty) 'code': settingsAnswer.code}, settingsAnswer.status);
    }
    final userId = body['userId'] as String? ?? '';
    if (request.method == 'DELETE') {
      list.removeWhere((row) => row['id'] == segments[3]);
    } else if (segments.length == 3) {
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
    final body = _bodyOf(request);
    sentSettingsChanges.add((_written(request), body));
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
    double value = 0,
    bool isOpenValue = false,
    double unitPrice = 0,
    double quantity = 0,
    String notes = '',
    double paid = 0,
    double pending = 0,
    bool isActive = true,
    String itemId = 'item-of-contract',
    String supplierId = 'supplier-of-contract',
    bool hasPayments = false,
  }) {
    final contract = <String, Object>{
      'id': 'contract-${_nextStructureId++}',
      'itemId': itemId,
      'supplierId': supplierId,
      'hasPayments': hasPayments,
      'supplierName': supplierName,
      'pending': pending,
      'itemName': itemName,
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
    final body = _bodyOf(request);
    sentSettingsChanges.add((_written(request), body));
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
      'showsTablePercentages': false,
      'subgroups': <Map<String, Object>>[
        for (final subgroup in ['', ...subgroups]) {'id': 'subgroup-${_nextStructureId++}', 'name': subgroup},
      ],
    };
    (category['items']! as List<Map<String, Object>>).add(item);
    return item;
  }

  /// The contract tables an item lists beside its subgroups, by item.
  final contractTables = <String, List<Map<String, Object>>>{};

  /// The order of an item's tables once one was sent, by item.
  final tableOrders = <String, List<String>>{};

  /// The tables of the item [itemId] as the API lists them: its general table named after it, each subgroup, then its contract tables, in the order last sent.
  List<Map<String, Object>> tablesOf(String itemId) {
    final item = [for (final list in categories.values) for (final category in list) ...category['items']! as List<Map<String, Object>>].singleWhere((row) => row['id'] == itemId);
    final tables = <Map<String, Object>>[
      for (final subgroup in item['subgroups']! as List<Map<String, Object>>)
        {'id': subgroup['id']!, 'kind': (subgroup['name']! as String).isEmpty ? 'general' : 'subgroup', 'name': (subgroup['name']! as String).isEmpty ? item['name']! : subgroup['name']!, 'count': 0},
      ...contractTables[itemId] ?? const <Map<String, Object>>[],
    ];
    final order = tableOrders[itemId] ?? const <String>[];
    return order.isEmpty ? tables : [for (final id in order) ...tables.where((table) => table['id'] == id)];
  }

  /// Every table an entry may go into, as `GET /entry-tables` answers (redix-app #84, redix-api #101): by active category, each active item that takes purchases with its general
  /// and named tables, and each that takes contractor payments with its active contracts. A contract on an item the test never added to a category is listed under one category of
  /// its own. Whoever moves money in the project also gets the revenue items, and last a group with no id and no name holding each active partner.
  List<Map<String, Object>> entryTablesOf(String projectId) {
    final movesMoney = (projects.singleWhere((project) => project['id'] == projectId)['permissions']! as List<String>).contains('moveMoney');
    final active = (contracts[projectId] ?? const <Map<String, Object>>[]).where((contract) => contract['isActive']! as bool).toList();
    List<Map<String, Object>> contractTablesOf(String itemId) => [
      for (final contract in active.where((contract) => contract['itemId'] == itemId)) {'id': contract['id']!, 'kind': 'contract', 'name': contract['supplierName']!},
    ];
    Map<String, Object> itemOf(Map<String, Object> item) {
      final type = item['type']! as String;
      final isRevenue = const ['sale', 'vatRefund', 'otherRevenue'].contains(type);
      return {
        'id': item['id']!,
        'name': item['name']!,
        'isRevenue': isRevenue,
        'tables': [
          if (type == 'purchases' || type == 'both' || isRevenue && movesMoney)
            for (final subgroup in item['subgroups']! as List<Map<String, Object>>)
              {'id': subgroup['id']!, 'kind': (subgroup['name']! as String).isEmpty ? 'general' : 'subgroup', 'name': (subgroup['name']! as String).isEmpty ? item['name']! : subgroup['name']!},
          if (type == 'contractorPayments' || type == 'both') ...contractTablesOf(item['id']! as String),
        ],
      };
    }

    final listed = categories[projectId] ?? const <Map<String, Object>>[];
    final itemIds = {for (final category in listed) for (final item in category['items']! as List<Map<String, Object>>) item['id']};
    final elsewhere = {for (final contract in active.where((contract) => !itemIds.contains(contract['itemId']))) contract['itemId']! as String: contract['itemName']!};
    return [
      for (final category in listed.where((category) => category['isActive']! as bool))
        {
          'id': category['id']!,
          'name': category['name']!,
          'items': [
            for (final item in (category['items']! as List<Map<String, Object>>).where((item) => item['isActive']! as bool).map(itemOf))
              if ((item['tables']! as List<Object>).isNotEmpty) item,
          ],
        },
      if (elsewhere.isNotEmpty)
        {
          'id': 'category-of-contracts',
          'name': 'العقود',
          'items': [
            for (final MapEntry(key: itemId, value: name) in elsewhere.entries) {'id': itemId, 'name': name, 'isRevenue': false, 'tables': contractTablesOf(itemId)},
          ],
        },
      if (movesMoney)
        {
          'id': 'category-capital',
          'name': 'رأس المال',
          'items': [
            for (final itemId in {for (final partner in partners[projectId] ?? const <Map<String, Object>>[]) partner['itemId']! as String})
              {
                'id': itemId,
                'name': 'رأس المال',
                'isRevenue': true,
                'tables': [
                  for (final partner in (partners[projectId] ?? const <Map<String, Object>>[]).where((partner) => partner['itemId'] == itemId))
                    {'id': partner['id']!, 'kind': 'partner', 'name': partner['name']!},
                ],
              },
          ],
        },
    ].where((category) => (category['items']! as List<Object>).isNotEmpty).toList();
  }

  http.Response _answerStructure(http.Request request) {
    final segments = request.url.pathSegments;
    final list = categories.putIfAbsent(segments[1], () => []);
    if (request.method == 'GET' && segments.length == 5 && segments[4] == 'tables') {
      return _json(tablesOf(segments[3]), 200);
    }
    if (request.method == 'GET') {
      return _json(list, 200);
    }
    final body = _bodyOf(request);
    sentStructureChanges.add((_written(request), body));
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
      case ['items', _, 'type']:
        row['type'] = body['type'] as String;
      case ['items', _, 'table-percentages']:
        row['showsTablePercentages'] = body['isOn'] as bool;
      case ['items', final itemId, 'tables', 'reorder']:
        tableOrders[itemId] = [for (final id in body['ids'] as List<dynamic>) id as String];
      case ['items', _, 'subgroups', final subgroupId] when request.method == 'DELETE':
        (row['subgroups']! as List<Map<String, Object>>).removeWhere((subgroup) => subgroup['id'] == subgroupId);
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
    final body = _bodyOf(request);
    sentStructureChanges.add((_written(request), body));
    if (structureAnswer.status >= 300) {
      return _json({if (structureAnswer.code.isNotEmpty) 'code': structureAnswer.code}, structureAnswer.status);
    }
    if (path.endsWith('/reorder')) {
      final order = body['ids'] as List<dynamic>;
      list.sort((first, second) => order.indexOf(first['id']).compareTo(order.indexOf(second['id'])));
    } else if (request.method == 'DELETE') {
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
        ..['showInReports'] = body['showInReports'] as bool
        ..update('options', (options) => [...options as List<String>, ...(body['newOptions'] as List<dynamic>? ?? const []).cast<String>()]);
    }
    return _json({}, 200);
  }

  /// Adds a user to what the API holds.
  Map<String, Object> addUser(String displayName, {required String username, String mobile = ''}) {
    final user = <String, Object>{
      'id': 'user-${users.length}',
      'username': username,
      'displayName': displayName,
      'mobile': mobile,
      'mustChangePassword': false,
      'projects': <Map<String, Object>>[],
    };
    users.add(user);
    return user;
  }

  /// Gives [user], as [addUser] answered them, [permissions] in the project [projectId], those not held already.
  void give(Map<String, Object> user, String projectId, List<String> permissions) {
    final project = projects.singleWhere((project) => project['id'] == projectId);
    final lines = user['projects'] as List<Map<String, Object>>;
    if (!lines.any((line) => line['projectId'] == projectId)) {
      lines.add({'projectId': projectId, 'name': project['name'] as String, 'isInactive': false, 'permissions': <String>[], 'partnerIds': <String>[]});
    }
    final line = lines.singleWhere((line) => line['projectId'] == projectId);
    final held = line['permissions']! as List<String>;
    for (final permission in permissions.where((permission) => !held.contains(permission))) {
      held
        ..removeWhere((other) => _capitalTicks.contains(permission) && _capitalTicks.contains(other))
        ..add(permission);
    }
    if (!held.contains('seeChosenCapital')) {
      (line['partnerIds']! as List<String>).clear();
    }
  }

  /// Makes [user], as [addUser] answered them, inactive in the project [projectId], as its manager's «تعطيل» does (redix-api #126 D1).
  void makeUserInactive(Map<String, Object> user, String projectId) => _lineOf(user, projectId)['isInactive'] = true;

  /// The line of [user] for the project [projectId].
  static Map<String, Object> _lineOf(Map<String, Object> user, String projectId) => (user['projects'] as List<Map<String, Object>>).singleWhere((line) => line['projectId'] == projectId);

  /// The two capital ticks, which the API lets nobody hold together (redix-api #106).
  static const _capitalTicks = {'seeAllCapital', 'seeChosenCapital'};

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
    final body = _bodyOf(request);
    sentUserChanges.add((_written(request), body));
    if (userAnswer.status >= 300) {
      return _json({if (userAnswer.code.isNotEmpty) 'code': userAnswer.code}, userAnswer.status);
    }
    if (segments.length == 3) {
      final user = addUser(body['displayName'] as String, username: body['username'] as String, mobile: body['mobile'] as String);
      give(user, projectId, ['readProject', ...(body['permissions'] as List<dynamic>).cast<String>()]);
      (user['projects'] as List<Map<String, Object>>).singleWhere((line) => line['projectId'] == projectId)
        ..['roleName'] = body['roleName'] as String
        ..['partnerIds'] = (body['partnerIds'] as List<dynamic>).cast<String>().toList();
      return _json(_inProject(user, projectId), 201);
    }
    if (segments[3] == 'existing') {
      final user = users.singleWhere((user) => user['username'] == body['username']);
      give(user, projectId, reader);
      return _json(_inProject(user, projectId), 200);
    }
    final user = users.singleWhere((user) => user['id'] == segments[3]);
    final lines = user['projects'] as List<Map<String, Object>>;
    if (segments.last == 'role-name') {
      lines.singleWhere((line) => line['projectId'] == projectId)['roleName'] = body['roleName'] as String;
    } else if (segments.last == 'disable' || segments.last == 'enable') {
      _lineOf(user, projectId)['isInactive'] = segments.last == 'disable';
    } else if (segments[4] == 'partners') {
      if (request.method != 'DELETE') {
        give(user, projectId, ['seeChosenCapital']);
      }
      final chosen = lines.singleWhere((line) => line['projectId'] == projectId)['partnerIds']! as List<String>;
      chosen.remove(segments[5]);
      if (request.method != 'DELETE') {
        chosen.add(segments[5]);
      }
    } else if (request.method != 'DELETE') {
      give(user, projectId, [segments[5]]);
    } else if (segments[5] == 'readProject') {
      lines.removeWhere((line) => line['projectId'] == projectId);
    } else {
      final line = lines.singleWhere((line) => line['projectId'] == projectId);
      (line['permissions']! as List<String>).remove(segments[5]);
      if (segments[5] == 'seeChosenCapital') {
        (line['partnerIds']! as List<String>).clear();
      }
    }
    return _json(_inProject(user, projectId), 200);
  }

  http.Response _answerUsers(http.Request request) {
    if (request.method == 'GET') {
      return _json(users, 200);
    }
    final body = _bodyOf(request);
    final path = request.url.path;
    sentUserChanges.add((_written(request), body));
    if (userAnswer.status >= 300) {
      return _json({if (userAnswer.code.isNotEmpty) 'code': userAnswer.code}, userAnswer.status);
    }
    final segments = request.url.pathSegments;
    final user = users.singleWhere((user) => user['id'] == segments[1]);
    if (!path.endsWith('/reset-password')) {
      user['displayName'] = body['displayName'] as String;
      user['mobile'] = body['mobile'] as String;
    }
    return _json(user, 200);
  }

  /// Records the entry the app sent to the one route, or the change of one, and answers as [entryAnswer] says (redix-api #110).
  http.Response _recordEntry(http.Request request) {
    sentEntryPaths.add(_written(request));
    sentEntries.add(_bodyOf(request));
    return _json(entryAnswer.body, entryAnswer.status);
  }

  /// What the app sent [request] to: its path, with its query, led by its method when that is not POST, so a test sees a plain edit put and a delete deleted (redix-api #98).
  String _written(http.Request request) {
    final sent = request.url.hasQuery ? '${request.url.path}?${request.url.query}' : request.url.path;
    return request.method == 'POST' ? sent : '${request.method} $sent';
  }

  /// What [request] carries as JSON; nothing for a delete, which has no body.
  Map<String, dynamic> _bodyOf(http.Request request) => request.body.isEmpty ? <String, dynamic>{} : jsonDecode(request.body) as Map<String, dynamic>;

  /// Answers as bytes with no character set, as a JSON reply may arrive, so reading Arabic takes UTF-8 on the app's side.
  http.Response _json(Object body, int status) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

  /// Adds a project waiting for the admin.
  void addRegistered(String name, {String managerName = 'ريم', String managerUsername = 'reem', String managerMobile = '0500000000', List<String> units = const ['الفلة الغربية'], String description = ''}) {
    registered.add({
      'id': 'registered-${registered.length}',
      'name': name,
      'startDate': '2026-11-05',
      'units': units,
      'managerName': managerName,
      'managerUsername': managerUsername,
      'managerMobile': managerMobile,
      'description': description,
    });
  }

  http.Response _answerRegistration(http.Request request) {
    final path = request.url.path;
    if (request.method == 'GET') {
      return _json(registered, 200);
    }
    final body = _bodyOf(request);
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
    sentProjectChanges.add((_written(request), _bodyOf(request)));
    if (projectAnswer.status >= 300) {
      return _json({if (projectAnswer.code.isNotEmpty) 'code': projectAnswer.code}, projectAnswer.status);
    }
    final removing = request.method == 'DELETE';
    defaultProjectId = removing ? '' : segments[1];
    return _json({'defaultProjectId': defaultProjectId}, 200);
  }

  /// What a removal took away, to put back where it was on its undo (redix-api #119).
  final _removed = <String, (List<Map<String, Object>>, int, Map<String, Object>)>{};

  Future<http.Response> _changeEntry(http.Request request) async {
    final segments = request.url.pathSegments;
    final action = request.method == 'DELETE' ? 'delete' : segments[4];
    sentEntryChanges.add((segments[3], action, _bodyOf(request)));
    await heldEntryChange.future;
    if (entryChangeAnswer.status >= 300) {
      return _json({'code': entryChangeAnswer.code}, entryChangeAnswer.status);
    }
    switch (action) {
      case 'submit':
        entryRows.singleWhere((row) => row['id'] == segments[3])['status'] = 'pendingApproval';
      case 'delete':
        for (final rows in [entryRows, movementRows]) {
          final index = rows.indexWhere((row) => row['id'] == segments[3]);
          if (index >= 0) {
            _removed[segments[3]] = (rows, index, rows.removeAt(index));
          }
        }
      case 'restore':
        final (rows, index, row) = _removed.remove(segments[3])!;
        rows.insert(index, row);
    }
    return _json(const <String, Object>{}, 200);
  }

  FutureOr<http.Response> _answerProjects(http.Request request) {
    final segments = request.url.pathSegments;
    if (segments.last == 'default') {
      return _answerDefault(request);
    }
    if (segments.length == 2 && (segments[1] == 'register' || segments[1] == 'registered') || segments.length == 3 && (segments[2] == 'approve' || segments[2] == 'reject')) {
      return _answerRegistration(request);
    }
    if (segments.length >= 3 && segments[2] == 'users') {
      return _answerProjectUsers(request, segments[1]);
    }
    if (segments.length >= 3 && (segments[2] == 'default-columns' || segments.length >= 5 && segments[4] == 'columns')) {
      return _answerColumns(request);
    }
    if (segments.length == 3 && segments[2] == 'entry-tables') {
      return _json(entryTablesOf(segments[1]), 200);
    }
    if (segments.length >= 3 && (segments[2] == 'categories' || segments[2] == 'items')) {
      return _answerStructure(request);
    }
    if (segments.length >= 3 && segments[2] == 'payment-methods') {
      return _answerPaymentMethods(request);
    }
    if (segments.length == 4 && segments[2] == 'accounts' && segments[3] == 'history') {
      return _answerAccountHistory(request);
    }
    if (segments.length >= 3 && segments[2] == 'accounts') {
      return _answerAccounts(request);
    }
    if (segments.length == 3 && segments[2] == 'transfers') {
      return _answerTransfer(request);
    }
    if (segments.length == 4 && segments[2] == 'partners' && segments[3] == 'history') {
      return _answerPartnerHistory(request);
    }
    if (segments.length == 4 && segments[2] == 'approvals' && segments[3] == 'history') {
      return _answerApprovalHistory(request);
    }
    if (segments.length >= 3 && segments[2] == 'partners' && segments.last != 'movements') {
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
    if (request.method == 'POST' && segments.length == 3 && segments[2] == 'entries') {
      return _recordEntry(request);
    }
    if (segments.length == 3 && segments[2] == 'entries') {
      final take = int.tryParse(request.url.queryParameters['take'] ?? '') ?? 0;
      entryReads.add(take);
      entryQueries.add(request.url.queryParametersAll);
      final kept = entryRows.where((row) => _searchKeeps(row, request.url)).toList();
      return heldEntries.future.then((_) => _json(take > 0 ? kept.take(take).toList() : kept, 200));
    }
    if (segments.length == 4 && segments[2] == 'entries' && request.method == 'GET' && entryDetails.containsKey(segments[3])) {
      return _json(entryDetails[segments[3]]!, 200);
    }
    if (segments.length == 5 && segments[2] == 'entries' && const ['submit', 'restore'].contains(segments[4]) || request.method == 'DELETE' && segments.length == 4 && segments[2] == 'entries') {
      return _changeEntry(request);
    }
    if (request.method == 'GET' && segments.length == 5 && segments[2] == 'entries' && segments[4] == 'row') {
      entryRowReads.add(segments[3]);
      final row = entryRows.where((row) => row['id'] == segments[3]).firstOrNull;
      return _json(row ?? const {'code': 'notFound'}, row == null ? 404 : 200);
    }
    if (const ['pdf', 'xlsx'].contains(segments.last)) {
      sentFileReads.add(request.url.toString().replaceFirst('${request.url.scheme}://${request.url.authority}', ''));
      return http.Response.bytes(const [37, 80, 68, 70], 200);
    }
    if (segments.length == 4 && segments[2] == 'periodic-reports' && segments[3] == 'next') {
      return _json({'number': periodicRows.length + 1, 'waiting': waiting(expensesCount: pendingEntries.length)}, 200);
    }
    if (segments.length == 4 && segments[2] == 'periodic-reports') {
      return _json(periodicAnswer, 200);
    }
    if (segments.length == 3 && segments[2] == 'periodic-reports') {
      if (request.method == 'POST') {
        periodicRows.insert(0, {'number': periodicRows.length + 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 100});
      }
      return _json(request.method == 'POST' ? periodicRows.first : periodicRows, 200);
    }
    if (segments.length == 3 && segments[2] == 'summary') {
      return _json(summaryAnswer, 200);
    }
    if (segments.length == 5 && segments[2] == 'reports' && (segments[3] == 'items' || segments[3] == 'contracts')) {
      itemReportReads.add(request.url.path);
      return _json(itemReportAnswer, 200);
    }
    if (segments.length == 3 && segments[2] == 'capital') {
      return _json({'total': capitalTotal, 'partners': capitalLines}, 200);
    }
    if (segments.length == 5 && segments[2] == 'partners' && segments[4] == 'movements') {
      return _json(movementRows, 200);
    }
    if (segments.length == 4 && segments[2] == 'reconciliations' && segments[3] == 'latest') {
      return _json(reconciliationAnswer, 200);
    }
    if (segments.length >= 3 && segments[2] == 'reconciliations') {
      sentMoney.add((request.url.path, jsonDecode(request.body) as Map<String, dynamic>));
      return _json(moneyAnswer.status < 300 ? {'id': 'sent-${sentMoney.length}'} : {'code': moneyAnswer.code}, moneyAnswer.status);
    }
    if (segments.length == 4 && segments[2] == 'entries' && segments[3] == 'attachable') {
      return _json(attachableEntries, 200);
    }
    if (segments.length == 5 && segments[2] == 'entries' && segments[4] == 'invoice') {
      sentInvoices.add((segments[3], jsonDecode(request.body) as Map<String, dynamic>));
      return _json(invoiceAnswer.status < 300 ? const <String, Object>{} : {'code': invoiceAnswer.code}, invoiceAnswer.status);
    }
    if (segments.length == 4 && segments[2] == 'entries' && segments[3] == 'pending') {
      return _json(pendingEntries, 200);
    }
    if (segments.length == 4 && segments[2] == 'entries' && segments[3] == 'approve') {
      final named = ((jsonDecode(request.body) as Map<String, dynamic>)['entryIds'] as List<dynamic>).cast<String>();
      sentApprovals.add(named);
      final failed = [for (final id in named) if (approvalFailures.containsKey(id)) {'entryId': id, 'code': approvalFailures[id]}];
      pendingEntries.removeWhere((entry) => named.contains(entry['id']) && !approvalFailures.containsKey(entry['id']));
      return _json({'approved': [for (final id in named) if (!approvalFailures.containsKey(id)) id], 'failed': failed}, 200);
    }
    if (segments.length == 5 && segments[2] == 'entries' && segments[4] == 'reject') {
      final reason = (jsonDecode(request.body) as Map<String, dynamic>)['reason'] as String;
      sentRejections.add((segments[3], reason));
      if (reason.trim().isEmpty) {
        return _json({'code': 'reasonRequired'}, 400);
      }
      pendingEntries.removeWhere((entry) => entry['id'] == segments[3]);
      return _json(const <String, Object>{}, 200);
    }
    if (request.method == 'PUT' && segments.length == 4 && segments[2] == 'entries') {
      return _recordEntry(request);
    }
    if (request.method == 'GET' && segments.length == 4 && segments[2] == 'entries' && segments[3] != 'mine') {
      return _json(const {'code': 'notFound'}, 404);
    }
    if (segments.length >= 3 && segments[2] == 'documents') {
      if (request.method == 'GET') {
        return _json(documentRows, 200);
      }
      if (request.method == 'DELETE') {
        sentDocuments.add((_written(request), const {}));
        documentRows.removeWhere((row) => row['id'] == segments[3]);
        return _json(const <String, Object>{}, 200);
      }
      final form = utf8.decode(request.bodyBytes, allowMalformed: true);
      String field(String name) => RegExp('name="$name"\r\n(?:[^\r]+\r\n)*\r\n([^\r]*)\r\n').firstMatch(form)?.group(1) ?? '';
      final fileName = RegExp('filename="([^"]*)"').firstMatch(form)?.group(1) ?? '';
      sentDocuments.add((request.url.path, {'name': field('name'), 'group': field('group'), 'file': fileName}));
      documentRows.add({
        'id': 'document-${_nextStructureId++}',
        'name': field('name'),
        'group': field('group'),
        'attachmentId': 'attachment-${_nextStructureId++}',
        'fileName': fileName,
        'contentType': 'application/octet-stream',
        'sizeBytes': 4,
        'uploadedAt': '2026-11-07T20:00:00Z',
      });
      return _json(const <String, Object>{}, 200);
    }
    if (segments.length == 4 && segments[2] == 'attachments' && request.method == 'GET') {
      if (segments[3] == 'attachment-pdf') {
        return http.Response.bytes(const [37, 80, 68, 70], 200, headers: {'content-type': 'application/pdf', 'content-disposition': "attachment; filename=invoice.pdf; filename*=UTF-8''%D9%81%D8%A7%D8%AA%D9%88%D8%B1%D8%A9.pdf"});
      }
      return segments[3] == 'attachment-gone' ? http.Response('', 404) : http.Response.bytes(onePixelPng, 200, headers: {'content-type': 'image/png'});
    }
    if (segments.length >= 3 && segments[2] == 'attachments') {
      sentAttachments.add(latin1.decode(request.bodyBytes));
      sentAttachmentPaths.add(request.url.path);
      if (attachmentAnswer.status >= 300) {
        return _json({if (attachmentAnswer.code.isNotEmpty) 'code': attachmentAnswer.code}, attachmentAnswer.status);
      }
      final id = 'attachment-${_nextStructureId++}';
      keptAttachmentIds.add(id);
      return _json({'id': id, 'fileName': RegExp('filename="([^"]*)"').firstMatch(latin1.decode(request.bodyBytes))!.group(1)!}, attachmentAnswer.status);
    }
    if (segments.length >= 3 && segments[2] == 'members') {
      return _json(members, 200);
    }
    if (request.method == 'GET') {
      return _json(projects, 200);
    }
    final body = _bodyOf(request);
    final path = request.url.path;
    sentProjectChanges.add((_written(request), body));
    if (projectAnswer.status >= 300) {
      return _json({if (projectAnswer.code.isNotEmpty) 'code': projectAnswer.code}, projectAnswer.status);
    }
    if (path == '/projects') {
      return _json(addProject(body['name'] as String, startDate: body['startDate'] as String, units: (body['units'] as List<dynamic>).cast<String>(), description: body['description'] as String), 201);
    }
    final project = projects.singleWhere((project) => project['id'] == request.url.pathSegments[1]);
    final units = project['units'] as List<Map<String, String>>;
    if (path.endsWith('/close')) {
      project['status'] = 'finished';
    } else if (path.endsWith('/description')) {
      project['description'] = (body['description'] as String).trim();
    } else if (segments.length == 2) {
      project['name'] = body['name'] as String;
    } else if (request.method == 'DELETE') {
      units.removeWhere((unit) => unit['id'] == segments[3]);
    } else if (segments.length == 4) {
      units.singleWhere((unit) => unit['id'] == segments[3])['name'] = body['name'] as String;
    } else {
      final unit = {'id': '${project['id']}-unit-${units.length}', 'name': body['name'] as String};
      units.add(unit);
    }
    return _json(project, 200);
  }
}

/// The id of no entry.
const emptyGuid = '00000000-0000-0000-0000-000000000000';

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
  LocalStore? store,
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  FlutterSecureStorage.setMockInitialValues(Map.of(stored));
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  if (tester.view.physicalSize == const Size(2400, 1800)) {
    tester.view.physicalSize = const Size(2400, 7200);
    addTearDown(tester.view.resetPhysicalSize);
  }
  final session = Session(const FlutterSecureStorage(), Biometrics(prompt ?? FakePrompt()), store ?? MemoryStore());
  final language = AppLanguage();
  final localConfig = LocalConfig();
  await http.runWithClient(() async {
    await session.restore();
    await language.restore();
    await localConfig.restore();
    await tester.pumpWidget(RedixApp(session: session, language: language, localConfig: localConfig, capture: capture ?? FakeCapture()));
    await tester.pumpAndSettle();
  }, () => api.client);
  return session;
}

/// Puts the app behind another, as a person who leaves REDIX for WhatsApp does: each state the phone passes through, in order, as AppLifecycleListener requires.
Future<void> sendToBackground(WidgetTester tester, FakeApi api) => _passThrough(tester, api, [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);

/// Brings the app back to the screen from behind another, as a person returning to REDIX does (redix-api #126 R6).
Future<void> bringBack(WidgetTester tester, FakeApi api) => _passThrough(tester, api, [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);

Future<void> _passThrough(WidgetTester tester, FakeApi api, List<AppLifecycleState> states) => act(tester, api, () async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
});

/// True when the element keyed [key] sits in its screen's title bar: within the height the screen's app bar takes from the top.
bool isInTitleBar(WidgetTester tester, Key key) => tester.getRect(find.byKey(key)).bottom <= Scaffold.of(tester.element(find.byKey(key))).appBarMaxHeight!;

/// True when the button keyed [key] works; a screen's add button shows grayed without the permission rather than hidden (issue #85).
bool isEnabled(WidgetTester tester, Key key) => switch (tester.widget(find.byKey(key))) {
  final IconButton icon => icon.onPressed != null,
  final widget => (widget as ButtonStyleButton).enabled,
};

/// Starts the app signed in, with [capture] as the phone's camera and files and [store] as its storage, and opens the first project from the list.
Future<void> openProject(WidgetTester tester, FakeApi api, {InvoiceCapture? capture, LocalStore? store}) async {
  await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture, store: store);
  await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
}

/// The pages of the home's Project settings, four buttons each (Muteb, 11 Nov 2026).
final projectSettingPages = find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith('home.settingsPages.'));

/// Swipes the home's Project settings one page on, as a person does: toward the start of the reading line, so in Arabic the next page comes from the left; back a page
/// when [back].
Future<void> swipeProjectSettings(WidgetTester tester, {bool back = false}) async {
  await tester.ensureVisible(projectSettingPages);
  await tester.pumpAndSettle();
  final width = tester.getSize(projectSettingPages).width;
  final rightToLeft = Directionality.of(tester.element(projectSettingPages)) == TextDirection.rtl;
  await tester.drag(projectSettingPages, Offset((rightToLeft != back ? width : -width) * 0.8, 0));
  await tester.pumpAndSettle();
}

/// Swipes the home's Project settings page by page until the button keyed [key] shows: on to the last page, then back to the first. Left where it ends, showing [key]
/// whenever any page holds it, so a key still not found after it is on none of them. Nothing when it shows already or no Project settings are on screen.
Future<void> showProjectSetting(WidgetTester tester, Key key) async {
  for (final back in [false, true]) {
    for (var turn = 0; turn < 4 && find.byKey(key).evaluate().isEmpty && projectSettingPages.evaluate().isNotEmpty; turn++) {
      await swipeProjectSettings(tester, back: back);
    }
  }
}

/// Scrolls [target] into view. A button of the home's Project settings is brought in by scrolling their card, since scrolling the button itself would also turn
/// their pages and leave them between two.
Future<void> bringIntoView(WidgetTester tester, Finder target) async {
  final inSettings = find.descendant(of: projectSettingPages, matching: target).evaluate().isNotEmpty;
  await tester.ensureVisible(inSettings ? projectSettingPages : target);
  await tester.pumpAndSettle();
}

/// redix-app #98, D1: the form's error [errorKey] stands above the form's first field [fieldKey], shown on the screen.
void expectErrorAbove(WidgetTester tester, Key errorKey, Key fieldKey) {
  expect(find.byKey(errorKey).hitTestable(), findsOneWidget, reason: 'redix-app #98 R4: the error is brought into view');
  expect(tester.getTopLeft(find.byKey(errorKey)).dy, lessThan(tester.getTopLeft(find.byKey(fieldKey)).dy), reason: "redix-app #98: a form's error stands above its first field");
}

/// Opens the screen at [path] from the open project's home, as a Project settings button would, for a screen whose button is grayed until a later release while its
/// work stays (Muteb, 12 Nov 2026): the VAT refund.
Future<void> openFromTheHome(WidgetTester tester, FakeApi api, String path, {String projectId = 'project-0'}) {
  final card = find.byKey(HomeScreen.cardKey(projectId));
  final project = tester.widget<ProjectSettingsCard>(card).project;
  return act(tester, api, () async => unawaited(GoRouter.of(tester.element(card)).push(path, extra: project)));
}

/// The name the VAT statement gives its files for the quarter it opens on, this one (UC-057): `vat-` and the quarter's first and last day.
String thisQuarterVat() {
  final start = DateTime(DateTime.now().year, (DateTime.now().month - 1) ~/ 3 * 3 + 1);
  return 'vat-${start.toIso8601String().substring(0, 10)}-${DateTime(start.year, start.month + 3, 0).toIso8601String().substring(0, 10)}';
}

/// Taps the widget keyed [key], scrolled into view first; a button of the home's Project settings is swiped to first.
Future<void> scrollAndTap(WidgetTester tester, FakeApi api, Key key) async {
  await showProjectSetting(tester, key);
  await bringIntoView(tester, find.byKey(key));
  await act(tester, api, () => tester.tap(find.byKey(key)));
}

/// What is dragged to scroll a list's rows, as opposed to the search line over it, whose field scrolls its own text (redix-app #104).
final listRows = find.byKey(ApiListBody.rowsKey);

/// Opens a list's filter line from the title bar's filter icon (redix-app #104, version 3); nothing when it shows already.
Future<void> openFilters(WidgetTester tester, FakeApi api) async {
  if (tester.widget<IconButton>(find.byKey(SearchIcons.filtersKey)).isSelected != true) {
    await act(tester, api, () => tester.tap(find.byKey(SearchIcons.filtersKey)));
  }
}

/// Folds a list's filter line again, as the title bar's filter icon does.
Future<void> foldFilters(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(SearchIcons.filtersKey)));

/// Types [typed] in a list's search line, opening it from the title bar's search icon first, and waits as long as a line whose list the API searches pauses before
/// handing it on (findings row 210).
Future<void> searchFor(WidgetTester tester, FakeApi api, String typed) async {
  if (find.byKey(SearchLine.searchKey).evaluate().isEmpty) {
    await act(tester, api, () => tester.tap(find.byKey(SearchIcons.searchKey)));
  }
  await act(tester, api, () async {
    await tester.enterText(find.byKey(SearchLine.searchKey), typed);
    await tester.pump(SearchLine.apiPause);
  });
}

/// Opens Settings from the card of the open project [projectId].
Future<void> openSettings(WidgetTester tester, FakeApi api, {String projectId = 'project-0'}) async {
  await tester.ensureVisible(find.byKey(HomeScreen.sharedSettingsKey(projectId)));
  await tester.pumpAndSettle();
  await act(tester, api, () => tester.tap(find.byKey(HomeScreen.sharedSettingsKey(projectId))));
}

/// Swipes the row keyed [rowKey] from its end toward its start, as removing it does (redix-api #102): right to left in English, left to right in Arabic, over [share] of
/// its width, and lets the app run.
Future<void> swipeToAsk(WidgetTester tester, FakeApi api, Key rowKey, {double share = 0.8}) async {
  final row = find.byKey(rowKey.swipe);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  final width = tester.getSize(row).width * share;
  final towardStart = Directionality.of(tester.element(row)) == TextDirection.rtl ? width : -width;
  await act(tester, api, () => tester.drag(row, Offset(towardStart, 0)));
}

/// Swipes the row [rowKey] and confirms in the row what it asks, removing it (redix-api #119: a swipe asks in place).
Future<void> swipeToRemove(WidgetTester tester, FakeApi api, Key rowKey) async {
  await swipeToAsk(tester, api, rowKey);
  await act(tester, api, () => tester.tap(find.byKey(rowKey.confirm)));
}

/// Opens More info from the home of the open project [projectId] (redix-api 93; Muteb, 9 Nov 2026).
Future<void> openProjectInfo(WidgetTester tester, FakeApi api, {String projectId = 'project-0'}) =>
    scrollAndTap(tester, api, HomeScreen.projectInfoKey(projectId));

/// Taps [finder] and lets the app run half a second, with its requests reaching [api], without waiting for it to settle: a screen shows a spinner, which never settles,
/// while [api] holds an answer back.
Future<void> tapWhileWaiting(WidgetTester tester, FakeApi api, Finder finder) => http.runWithClient(() async {
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}, () => api.client);

/// Runs [action] and lets the app settle, with the app's requests reaching [api].
Future<void> act(WidgetTester tester, FakeApi api, Future<void> Function() action) => http.runWithClient(() async {
  await action();
  await tester.pumpAndSettle();
}, () => api.client);

/// Opens the ⋮ keyed [menuKey] and chooses [itemKey] in it.
Future<void> chooseFromMenu(WidgetTester tester, FakeApi api, Key menuKey, Key itemKey) async {
  await tester.ensureVisible(find.byKey(menuKey));
  await act(tester, api, () => tester.tap(find.byKey(menuKey)));
  await act(tester, api, () => tester.tap(find.byKey(itemKey)));
}

/// Opens the [MemberPicker] keyed [pickerKey] and chooses [userId] in its list; nobody when that is empty. The open list draws over the closed one, so the last match is the one tapped.
Future<void> chooseMember(WidgetTester tester, FakeApi api, Key pickerKey, String userId) async {
  await tester.ensureVisible(find.byKey(pickerKey.field));
  await act(tester, api, () => tester.tap(find.byKey(pickerKey.field)));
  await act(tester, api, () => tester.tap(find.byKey(MemberPicker.optionKey(userId))));
}

/// The color the frame of the entry [id]'s row is drawn in, which alone says where the entry stands (Muteb, 9 Nov 2026).
AppColor frameOf(WidgetTester tester, String id) {
  final card = find.byKey(EntriesScreen.rowKey(id).card);
  final side = (tester.widget<Card>(card).shape! as RoundedRectangleBorder).side.color;
  return AppColor.values.firstWhere((role) => role.of(tester.element(card)) == side);
}
