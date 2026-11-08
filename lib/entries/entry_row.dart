import '../auth/permission.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../suppliers/arabic_spelling.dart';

/// An entry on a list (UC-037).
class EntryRow {
  /// An entry as the API answers it.
  EntryRow.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      status = json['status'] as String,
      rejectionReason = json['rejectionReason'] as String,
      date = DateTime.parse(json['entryDate'] as String),
      amount = (json['amount'] as num).toDouble(),
      itemName = json['itemName'] as String,
      supplierName = json['supplierName'] as String,
      invoiceNumber = json['invoiceNumber'] as String,
      authorName = json['authorName'] as String,
      isMine = json['isMine'] as bool,
      isReversed = json['isReversed'] as bool;

  /// The entry's id.
  final String id;

  /// `purchase` or `contractorPayment`.
  final String kind;

  /// `draft`, `pendingApproval`, `approved` or `rejected`.
  final String status;

  /// Why it was rejected, while it stands rejected; empty otherwise.
  final String rejectionReason;

  /// Its date.
  final DateTime date;

  /// What was paid.
  final double amount;

  /// Its item.
  final String itemName;

  /// Its supplier, or its contract's contractor.
  final String supplierName;

  /// Its invoice's number; empty when it has none.
  final String invoiceNumber;

  /// Who entered it.
  final String authorName;

  /// True when the signed-in user entered it.
  final bool isMine;

  /// True when it was reversed, or is itself a reversal.
  final bool isReversed;

  /// True while it is not sent yet.
  bool get isDraft => status == 'draft';

  /// Whether [permission] lets the signed-in user act on this entry in [project] now: it is not approved, and it is theirs and not waiting, or they handle others' entries.
  /// The one answer for the entry's sheet and its swipe (redix-api #102).
  bool allows(Project project, Permission permission) =>
      !project.isFinished && !isApproved && project.may(permission) && (isMine ? !isPending || project.may(Permission.manageAnyEntry) : project.may(Permission.manageAnyEntry));

  /// True while it waits for a decision.
  bool get isPending => status == 'pendingApproval';

  /// True once approved.
  bool get isApproved => status == 'approved';

  /// True when it was rejected.
  bool get isRejected => status == 'rejected';

  /// True for a contractor's payment.
  bool get isContractorPayment => kind == 'contractorPayment';

  /// The word key of where it stands.
  String get statusWordKey => isReversed ? 'entries.reversed' : 'entries.$status';

  /// True when a row says where it stands: an approved entry says nothing, and a reversed one says so (Muteb, 7 Nov 2026).
  bool get showsStatus => statusWordKey != 'entries.approved';

  /// What a search matches it by (redix-app #84): its item, supplier or contractor, who entered it, an old bill's number and its amount, plain and as money, in one spelling.
  late final searchText = sameSpelling([itemName, supplierName, authorName, invoiceNumber, formatPlain(amount), formatMoney(amount)].join(' '));
}
