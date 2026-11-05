import '../api_object.dart';
import '../auth/session.dart';

/// A partner's part of the final surplus, as the API shares it (BR-27).
class LiquidationPart {
  /// A part as the API answers it.
  LiquidationPart.fromJson(Map<String, dynamic> json)
    : partnerId = json['partnerId'] as String,
      name = json['name'] as String,
      sharePercent = (json['sharePercent'] as num).toDouble(),
      amount = (json['amount'] as num).toDouble();

  /// The partner.
  final String partnerId;

  /// Their name.
  final String name;

  /// Their share, with ten decimals (BR-28).
  final double sharePercent;

  /// Their part; negative for their part of a deficit.
  final double amount;
}

/// A part already shared out.
class LiquidationShare {
  /// A part as the API answers it.
  LiquidationShare.fromJson(Map<String, dynamic> json)
    : entryId = json['entryId'] as String,
      partnerName = json['partnerName'] as String,
      date = DateTime.parse(json['date'] as String),
      amount = (json['amount'] as num).toDouble(),
      accountName = json['accountName'] as String;

  /// The entry.
  final String entryId;

  /// The partner.
  final String partnerName;

  /// The day.
  final DateTime date;

  /// What they took; negative for what they paid in.
  final double amount;

  /// The account it went through.
  final String accountName;
}

/// A project's liquidation, as the API reckons it.
class LiquidationFigures {
  /// The liquidation as the API answers it.
  LiquidationFigures.fromJson(Map<String, dynamic> json)
    : surplus = (json['surplus'] as num).toDouble(),
      pendingCount = json['pendingCount'] as int,
      parts = [
        for (final row in json['parts'] as List<dynamic>)
          if ((row as Map<String, dynamic>)['amount'] != 0) LiquidationPart.fromJson(row),
      ],
      distributed = [for (final row in json['distributed'] as List<dynamic>) LiquidationShare.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  LiquidationFigures.none() : surplus = 0, pendingCount = 0, parts = const [], distributed = const [];

  /// What is left to share out: the surplus, or a deficit when negative.
  final double surplus;

  /// Entries waiting for approval, which hold the close (BR-35).
  final int pendingCount;

  /// Each partner's part of it that is not nothing.
  final List<LiquidationPart> parts;

  /// What was already shared out.
  final List<LiquidationShare> distributed;
}

/// How one partner's part goes: paid out of, or a deficit paid into, an account here, or carried to their line in a later project.
class LiquidationLine {
  /// The account here.
  var accountId = '';

  /// True when it is carried rather than paid.
  var isCarry = false;

  /// The later project; empty until chosen.
  var targetProjectId = '';

  /// The partner there; empty until chosen.
  var targetPartnerId = '';

  /// The account there; empty until chosen.
  var targetAccountId = '';

  /// Whether everything it needs is chosen.
  bool get isComplete => accountId.isNotEmpty && (!isCarry || (targetProjectId.isNotEmpty && targetPartnerId.isNotEmpty && targetAccountId.isNotEmpty));

  /// What the API is sent for the partner [partnerId].
  Map<String, Object> toSend(String partnerId) => {
    'partnerId': partnerId,
    'accountId': accountId,
    if (isCarry) ...{'targetProjectId': targetProjectId, 'targetPartnerId': targetPartnerId, 'targetAccountId': targetAccountId},
  };
}

/// A project's liquidation (UC-061), and the way to share it out and close the project. The change returns an empty string once made, otherwise the word key of the refusal.
class Liquidation extends ApiObject<LiquidationFigures> {
  /// The liquidation of the project [projectId], seen through [session].
  Liquidation(Session session, this.projectId)
    : super(session, '/projects/$projectId/liquidation', 'capital', (json) => LiquidationFigures.fromJson(json! as Map<String, dynamic>), LiquidationFigures.none());

  /// The project.
  final String projectId;

  /// Shares out the surplus on [date], each partner's part as [lines] says, and closes the project.
  Future<String> liquidate(DateTime date, Map<String, LiquidationLine> lines) => change('/projects/$projectId/liquidation', {
    'date': date.toIso8601String().substring(0, 10),
    'lines': [for (final MapEntry(key: partnerId, value: line) in lines.entries) line.toSend(partnerId)],
  });
}
