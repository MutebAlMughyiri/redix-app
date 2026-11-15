import 'dart:convert';

import 'entry_attachment.dart';
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
      amount: (entry['amount'] as num).toDouble(),
      date: DateTime.parse(entry['entryDate'] as String),
      description: entry['description'] as String,
      accountId: entry['accountId'] as String,
      paymentMethodId: expense['paymentMethodId'] as String,
      supplierId: purchase['supplierId'] as String,
      isOutsideContract: payment['isOutsideContract'] as bool,
      attachments: [for (final file in files) EntryAttachment.fromJson(file)],
      columnValues: (jsonDecode(entry['columnValues'] as String) as Map<String, dynamic>).map((key, value) => MapEntry(key, '$value')),
    );
  }

  /// An entry that could not be read.
  SavedEntry.none()
    : tableId = '',
      status = EntryStatus.draft,
      amount = 0,
      date = DateTime(1),
      description = '',
      accountId = '',
      paymentMethodId = '',
      supplierId = '',
      isOutsideContract = false,
      attachments = const [],
      columnValues = const {};

  SavedEntry._({
    required this.tableId,
    required this.status,
    required this.amount,
    required this.date,
    required this.description,
    required this.accountId,
    required this.paymentMethodId,
    required this.supplierId,
    required this.isOutsideContract,
    required this.attachments,
    required this.columnValues,
  });

  /// The table it went into: an item's group, a contract or a partner, as the API names it (redix-api #110).
  final String tableId;

  /// Where it stands.
  final EntryStatus status;

  /// Its total; negative for a credit note or a deduction.
  final double amount;

  /// Its date.
  final DateTime date;

  /// «الوصف», what it says (redix-api #129).
  final String description;

  /// The account that paid it.
  final String accountId;

  /// How it was paid; empty when nobody said.
  final String paymentMethodId;

  /// A purchase's supplier; empty when it names none, which a purchase may (redix-api #129), and for anything else.
  final String supplierId;

  /// True for a payment outside its contract.
  final bool isOutsideContract;

  /// Every file it holds, the oldest first, which its page lists (redix-app #115, AC-46.10g); none when it has none.
  final List<EntryAttachment> attachments;

  /// Its first file, the one Add entry shows and sends again; empty when it has none.
  String get attachmentId => attachments.isEmpty ? '' : attachments.first.attachmentId;

  /// The values of its item's columns it keeps under their keys, the unit price, the quantity, the product, «نوع القيد» and «نوع الحركة» among them (redix-api #129, R5).
  final Map<String, String> columnValues;

  /// True when nothing could be read.
  bool get isNone => tableId.isEmpty;

  /// What the figures of the contract [contractId] already hold of it: its amount once it waits or is approved inside that contract, otherwise nothing.
  double heldBy(String contractId) => tableId == contractId && !isOutsideContract && (status == EntryStatus.pendingApproval || status == EntryStatus.approved) ? amount : 0;
}
