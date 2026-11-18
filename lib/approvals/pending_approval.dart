// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../entries/entry_kind.dart';
import '../entries/entry_row.dart';
import '../words/words.dart';

/// An entry waiting for Finance's decision (UC-031).
class PendingApproval {
  /// An entry as the API answers it.
  PendingApproval.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      number = json['number'] as int,
      kind = EntryKind.values.byName(json['kind'] as String),
      date = DateTime.parse(json['entryDate'] as String),
      amount = (json['amount'] as num).toDouble(),
      itemName = json['itemName'] as String,
      supplierName = json['supplierName'] as String,
      invoiceNumber = json['invoiceNumber'] as String,
      accountName = json['accountName'] as String,
      description = json['description'] as String,
      attachmentId = json['attachmentId'] as String,
      contentType = json['contentType'] as String,
      fileName = json['fileName'] as String,
      authorName = json['authorName'] as String,
      partnerName = json['partnerName'] as String,
      accountBalance = (json['accountBalance'] as num).toDouble(),
      accountWaiting = (json['accountWaiting'] as num).toDouble(),
      accountShortBy = (json['accountShortBy'] as num).toDouble();

  /// The entry's id.
  final String id;

  /// «رقم القيد», its number in the project (redix-api #128, FR-54).
  final int number;

  /// What it is.
  final EntryKind kind;

  /// Its date.
  final DateTime date;

  /// Its total.
  final double amount;

  /// Its item.
  final String itemName;

  /// Its supplier, or the contract's contractor.
  final String supplierName;

  /// The number of an older bill that had one; empty for the rest.
  final String invoiceNumber;

  /// What paid it.
  final String accountName;

  /// «الوصف», what it says (redix-api #129).
  final String description;

  /// Its file; empty when it has none.
  final String attachmentId;

  /// What the file is; empty when it has none.
  final String contentType;

  /// The file's name, which the phone shows once it is handed over; empty when it has none.
  final String fileName;

  /// Who entered it.
  final String authorName;

  /// A capital movement's partner; empty for any other entry (redix-api #101).
  final String partnerName;

  /// What its account holds now (redix-app #89).
  final double accountBalance;

  /// What waits to leave its account, this entry among it: every entry taking money out of it that waits for approval (Muteb, 10 Nov 2026).
  final double accountWaiting;

  /// How much more what waits on its account takes than the account holds; zero when it covers all of it. Nothing blocks it, but the inbox notes it (R5).
  final double accountShortBy;

  /// «قيد 312», what leads its details line, as it leads the entry card's (redix-api #128, AC-54.4).
  String numberIn(Words words) => EntryRow.numberOf(number, words);

  /// What names it on its card: a capital movement's partner, otherwise its item.
  String get title => EntryRow.titleOf(partnerName, itemName);

  /// The word key saying what a capital movement or a revenue entry is; empty for an expense, which its supplier explains.
  String get kindWordKey => kind.isExpense ? '' : kind.wordKey;

  /// True when it has a file to open.
  bool get hasFile => attachmentId.isNotEmpty;
}
