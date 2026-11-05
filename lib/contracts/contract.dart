import 'dart:math';

import '../attachments/attachment.dart';

/// A contract of a project, as the API answers it. The API reckons what remains; the app only draws it.
class Contract {
  /// The contract the API describes in [json].
  Contract.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      supplierName = json['supplierName'] as String,
      itemName = json['itemName'] as String,
      unitName = json['unitName'] as String,
      value = (json['value'] as num).toDouble(),
      isOpenValue = json['isOpenValue'] as bool,
      unitPrice = (json['unitPrice'] as num).toDouble(),
      quantity = (json['quantity'] as num).toDouble(),
      notes = json['notes'] as String,
      paid = (json['paid'] as num).toDouble(),
      remaining = (json['remaining'] as num).toDouble(),
      isOverrun = json['isOverrun'] as bool,
      isActive = json['isActive'] as bool,
      documents = [for (final document in json['documents'] as List<dynamic>) Attachment.fromJson(document as Map<String, dynamic>)];

  /// No contract, for the dialog that adds one.
  Contract.none() : documents = [], id = '', supplierName = '', itemName = '', unitName = '', value = 0, isOpenValue = false, unitPrice = 0, quantity = 0, notes = '', paid = 0, remaining = 0, isOverrun = false, isActive = true;

  /// The contract's id; empty for a contract not added yet.
  final String id;

  /// The contractor's name.
  final String supplierName;

  /// The item's name.
  final String itemName;

  /// The unit's name.
  final String unitName;

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

  /// What has been paid inside the contract.
  final double paid;

  /// The value less what was paid, below zero once overrun; 0 for an open-value contract.
  final double remaining;

  /// Whether what was paid goes beyond the value, which shows an alert.
  final bool isOverrun;

  /// False once disabled.
  final bool isActive;

  /// The documents it carries, in the order they were kept.
  final List<Attachment> documents;

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
