import 'dart:convert';

import 'entry_kind.dart';

/// An expense as the API keeps it, read to fill Add entry when it is changed (UC-033, findings row 165).
class SavedEntry {
  /// The entry as `GET /projects/{id}/entries/{entryId}` answers it.
  factory SavedEntry.fromJson(Map<String, dynamic> json) {
    final entry = json['entry'] as Map<String, dynamic>;
    final expense = json['expense'] as Map<String, dynamic>;
    final purchase = json['purchase'] as Map<String, dynamic>;
    final payment = json['contractorPayment'] as Map<String, dynamic>;
    final files = (json['attachments'] as List<dynamic>).cast<Map<String, dynamic>>();
    final creditNoteOf = (json['links'] as List<dynamic>).cast<Map<String, dynamic>>().where((link) => link['type'] == 'creditNoteOf').map((link) => link['linkedEntryId'] as String);
    final isPayment = EntryKind.values.byName(entry['kind'] as String) == EntryKind.contractorPayment;
    return SavedEntry._(
      itemId: expense['itemId'] as String,
      tableId: (isPayment ? payment['contractId'] : expense['subgroupId']) as String,
      amount: (entry['amount'] as num).toDouble(),
      date: DateTime.parse(entry['entryDate'] as String),
      notes: entry['notes'] as String,
      accountId: entry['accountId'] as String,
      paymentMethodId: expense['paymentMethodId'] as String,
      supplierId: purchase['supplierId'] as String,
      product: purchase['product'] as String,
      unitPrice: (purchase['unitPrice'] as num).toDouble(),
      quantity: (purchase['quantity'] as num).toDouble(),
      isOutsideContract: payment['isOutsideContract'] as bool,
      originalEntryId: creditNoteOf.firstOrNull ?? '',
      attachmentId: files.isEmpty ? '' : files.first['attachmentId'] as String,
      customValues: (jsonDecode(expense['customValues'] as String) as Map<String, dynamic>).map((key, value) => MapEntry(key, '$value')),
    );
  }

  /// An entry that could not be read.
  SavedEntry.none()
    : itemId = '',
      tableId = '',
      amount = 0,
      date = DateTime(1),
      notes = '',
      accountId = '',
      paymentMethodId = '',
      supplierId = '',
      product = '',
      unitPrice = 0,
      quantity = 0,
      isOutsideContract = false,
      originalEntryId = '',
      attachmentId = '',
      customValues = const {};

  SavedEntry._({
    required this.itemId,
    required this.tableId,
    required this.amount,
    required this.date,
    required this.notes,
    required this.accountId,
    required this.paymentMethodId,
    required this.supplierId,
    required this.product,
    required this.unitPrice,
    required this.quantity,
    required this.isOutsideContract,
    required this.originalEntryId,
    required this.attachmentId,
    required this.customValues,
  });

  /// Its item.
  final String itemId;

  /// The table it went into: a purchase's subgroup, a payment's contract.
  final String tableId;

  /// Its total; negative for a credit note or a deduction.
  final double amount;

  /// Its date.
  final DateTime date;

  /// What was noted.
  final String notes;

  /// The account that paid it.
  final String accountId;

  /// How it was paid; empty when nobody said.
  final String paymentMethodId;

  /// A purchase's supplier; empty for a payment.
  final String supplierId;

  /// What was bought; empty when nothing was said.
  final String product;

  /// The price of one; 0 when not given.
  final double unitPrice;

  /// How many; 0 when not given.
  final double quantity;

  /// True for a payment outside its contract.
  final bool isOutsideContract;

  /// The bill a credit note returns; empty for anything else.
  final String originalEntryId;

  /// Its file; empty when it has none.
  final String attachmentId;

  /// The values of the item's own columns, by key.
  final Map<String, String> customValues;

  /// True when nothing could be read.
  bool get isNone => itemId.isEmpty;

  /// True for a credit note.
  bool get isCreditNote => originalEntryId.isNotEmpty;
}
