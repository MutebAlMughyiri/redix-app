import 'dart:math';

import '../attachments/attachment.dart';

/// A contract of a project, as the API answers it. The API reckons what remains; the app only draws it.
class Contract {
  /// The contract the API describes in [json].
  Contract.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      itemId = json['itemId'] as String,
      supplierId = json['supplierId'] as String,
      hasPayments = json['hasPayments'] as bool,
      supplierName = json['supplierName'] as String,
      supplierVatNumber = json['supplierVatNumber'] as String,
      itemName = json['itemName'] as String,
      value = (json['value'] as num).toDouble(),
      isOpenValue = json['isOpenValue'] as bool,
      unitPrice = (json['unitPrice'] as num).toDouble(),
      quantity = (json['quantity'] as num).toDouble(),
      notes = json['notes'] as String,
      paid = (json['paid'] as num).toDouble(),
      pending = (json['pending'] as num).toDouble(),
      remaining = (json['remaining'] as num).toDouble(),
      isOverrun = json['isOverrun'] as bool,
      isActive = json['isActive'] as bool,
      documents = [for (final document in json['documents'] as List<dynamic>) Attachment.fromJson(document as Map<String, dynamic>)];

  /// No contract, for the dialog that adds one.
  Contract.none() : documents = [], id = '', itemId = '', supplierId = '', hasPayments = false, supplierName = '', supplierVatNumber = '', itemName = '', value = 0, isOpenValue = false, unitPrice = 0, quantity = 0, notes = '', paid = 0, pending = 0, remaining = 0, isOverrun = false, isActive = true;

  /// The contract's id; empty for a contract not added yet.
  final String id;

  /// The item it is for.
  final String itemId;

  /// The contractor.
  final String supplierId;

  /// Whether any payment names it: its contractor, item and unit then stay as they are.
  final bool hasPayments;

  /// The contractor's name.
  final String supplierName;

  /// The contractor's VAT number; empty for none.
  final String supplierVatNumber;

  /// The item's name.
  final String itemName;

  /// What was promised; 0 for an open-value contract.
  final double value;

  /// Whether its payments only add up, with no remaining and no alert.
  final bool isOpenValue;

  /// The price of one unit of work; 0 when not used.
  final double unitPrice;

  /// How many units of work; 0 when not used.
  final double quantity;

  /// Notes on the contract and its amendments; empty when none.
  final String notes;

  /// What has been paid inside the contract, which counts only once approved.
  final double paid;

  /// What waits for approval inside the contract, shown beside what was paid.
  final double pending;

  /// The value less what was paid, below zero once overrun; 0 for an open-value contract.
  final double remaining;

  /// Whether what was paid goes beyond the value, which shows an alert.
  final bool isOverrun;

  /// False once disabled.
  final bool isActive;

  /// The documents it carries, in the order they were kept.
  final List<Attachment> documents;

  /// What would remain after [payment], with what waits for approval counted too; 0 for an open-value contract. The API answers the same when it is saved.
  double remainingAfter(double payment) => isOpenValue ? 0 : value - paid - pending - payment;

  /// Whether [payment], with what waits for approval, goes beyond the value.
  bool isOverrunBy(double payment) => !isOpenValue && paid + pending + payment > value;

  /// The key of the word that says how it stands.
  String get standingWordKey {
    if (!isActive) {
      return 'contracts.disabled';
    }
    if (isOverrun) {
      return 'contracts.overrun';
    }
    if (isOpenValue) {
      return 'contracts.openValue';
    }
    return paid == 0 ? 'contracts.notStarted' : 'contracts.running';
  }

  /// How much of the bar is filled, from 0 to 1: all of it for an open-value contract, which has nothing to reach.
  double get progress => isOpenValue || value == 0 ? 1 : min(1, paid / value);
}

/// Which contracts the screen shows, each knowing its word and which contracts it keeps.
enum ContractFilter {
  /// Every contract.
  all('contracts.filterAll'),

  /// Those overrun.
  overrun('contracts.filterOverrun'),

  /// Those of open value.
  openValue('contracts.filterOpenValue');

  const ContractFilter(this.wordKey);

  /// The key of the word that names this filter.
  final String wordKey;

  /// Whether [contract] passes this filter.
  bool keeps(Contract contract) => switch (this) {
    all => true,
    overrun => contract.isOverrun,
    openValue => contract.isOpenValue,
  };
}
