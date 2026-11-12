import 'dart:convert';

import 'entry_kind.dart';
import 'entry_status.dart';

/// An entry as the API keeps it, whatever its table, read to fill Add entry when it is changed (UC-033, findings row 165, redix-api #110).
class SavedEntry {
  /// The entry as `GET /projects/{id}/entries/{entryId}` answers it.
  factory SavedEntry.fromJson(Map<String, dynamic> json) {
    final entry = json['entry'] as Map<String, dynamic>;
    final expense = json['expense'] as Map<String, dynamic>;
    final purchase = json['purchase'] as Map<String, dynamic>;
    final payment = json['contractorPayment'] as Map<String, dynamic>;
    final files = (json['attachments'] as List<dynamic>).cast<Map<String, dynamic>>();
    return SavedEntry._(
      tableId: json['tableId'] as String,
      status: EntryStatus.values.byName(entry['status'] as String),
      isWithdrawal: EntryKind.values.byName(entry['kind'] as String) == EntryKind.capitalOut,
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
      isCreditNote: EntryKind.values.byName(entry['kind'] as String) == EntryKind.purchase && (entry['amount'] as num) < 0,
      attachmentId: files.isEmpty ? '' : files.first['attachmentId'] as String,
      customValues: (jsonDecode(expense['customValues'] as String) as Map<String, dynamic>).map((key, value) => MapEntry(key, '$value')),
    );
  }

  /// An entry that could not be read.
  SavedEntry.none()
    : tableId = '',
      status = EntryStatus.draft,
      isWithdrawal = false,
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
      isCreditNote = false,
      attachmentId = '',
      customValues = const {};

  SavedEntry._({
    required this.tableId,
    required this.status,
    required this.isWithdrawal,
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
    required this.isCreditNote,
    required this.attachmentId,
    required this.customValues,
  });

  /// The table it went into: an item's group, a contract or a partner, as the API names it (redix-api #110).
  final String tableId;

  /// Where it stands.
  final EntryStatus status;

  /// True for a partner's withdrawal.
  final bool isWithdrawal;

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

  /// True for a credit note: a purchase kept with a minus amount, its own row, naming no bill (redix-api #119, D4).
  final bool isCreditNote;

  /// Its file; empty when it has none.
  final String attachmentId;

  /// The values of the item's own columns, by key.
  final Map<String, String> customValues;

  /// True when nothing could be read.
  bool get isNone => tableId.isEmpty;

  /// What the figures of the contract [contractId] already hold of it: its amount once it waits or is approved inside that contract, otherwise nothing.
  double heldBy(String contractId) => tableId == contractId && !isOutsideContract && (status == EntryStatus.pendingApproval || status == EntryStatus.approved) ? amount : 0;
}
