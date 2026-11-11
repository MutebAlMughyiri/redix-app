import '../auth/permission.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/arabic_spelling.dart';
import 'entry_kind.dart';
import 'entry_status.dart';

/// An entry on a list (UC-037).
class EntryRow {
  /// No entry: approved and nobody's, so nothing may be done to it.
  EntryRow.none()
    : id = '',
      kind = EntryKind.purchase,
      status = EntryStatus.approved,
      rejectionReason = '',
      date = DateTime(1),
      amount = 0,
      itemName = '',
      supplierName = '',
      invoiceNumber = '',
      authorName = '',
      isMine = false,
      isReversed = false,
      partnerName = '',
      notes = '',
      accountName = '',
      paymentMethodName = '',
      accountShortBy = 0;

  /// An entry as the API answers it.
  EntryRow.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = EntryKind.values.byName(json['kind'] as String),
      status = EntryStatus.values.byName(json['status'] as String),
      rejectionReason = json['rejectionReason'] as String,
      date = DateTime.parse(json['entryDate'] as String),
      amount = (json['amount'] as num).toDouble(),
      itemName = json['itemName'] as String,
      supplierName = json['supplierName'] as String,
      invoiceNumber = json['invoiceNumber'] as String,
      authorName = json['authorName'] as String,
      isMine = json['isMine'] as bool,
      isReversed = json['isReversed'] as bool,
      partnerName = json['partnerName'] as String,
      notes = json['notes'] as String,
      accountName = json['accountName'] as String,
      paymentMethodName = json['paymentMethodName'] as String,
      accountShortBy = (json['accountShortBy'] as num? ?? 0).toDouble();

  /// The entry's id.
  final String id;

  /// What it is.
  final EntryKind kind;

  /// Where it stands.
  final EntryStatus status;

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

  /// A partner's money's partner; empty for any other entry.
  final String partnerName;

  /// What was noted; empty for nothing.
  final String notes;

  /// The account it was paid from or reached.
  final String accountName;

  /// How an expense was paid; empty when nobody said, and for any other entry.
  final String paymentMethodName;

  /// How much more it takes than its account holds; zero when its account covers it, or once decided (redix-app #89).
  final double accountShortBy;

  /// What names it on a list: a partner's money's partner, otherwise its item.
  String get title => titleOf(partnerName, itemName);

  /// What an entry is called on a list: its partner's name for a partner's money, otherwise its item's.
  static String titleOf(String partnerName, String itemName) => partnerName.isEmpty ? itemName : partnerName;

  /// True for a purchase or a contractor payment, which Add entry opens to change.
  bool get isExpense => kind.isExpense;

  /// True while it is not sent yet.
  bool get isDraft => status == EntryStatus.draft;

  /// Whether [permission] lets the signed-in user act on this entry in [project] now: it is not approved, and it is theirs and not waiting, or they handle others' entries.
  /// The one answer for the entry's sheet and its swipe (redix-api #102).
  bool allows(Project project, Permission permission) =>
      !project.isFinished && !isApproved && project.may(permission) && (isMine ? !isPending || project.may(Permission.manageAnyEntry) : project.may(Permission.manageAnyEntry));

  /// True while it waits for a decision.
  bool get isPending => status == EntryStatus.pendingApproval;

  /// True once approved.
  bool get isApproved => status == EntryStatus.approved;

  /// True when it was rejected.
  bool get isRejected => status == EntryStatus.rejected;

  /// The word key of where it stands.
  String get statusWordKey => isReversed ? 'entries.reversed' : status.wordKey;

  /// What a search matches it by (redix-app #84): its item, supplier or contractor, who entered it, an old bill's number and its amount, plain and as money, in one spelling.
  late final searchText = sameSpelling([itemName, partnerName, supplierName, authorName, invoiceNumber, formatPlain(amount), formatMoney(amount)].join(' '));
}
