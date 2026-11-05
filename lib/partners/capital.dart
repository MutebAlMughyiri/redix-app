import '../api_object.dart';
import '../auth/session.dart';

/// One partner's capital (UC-044).
class PartnerCapital {
  /// A line as the API answers it.
  PartnerCapital.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      isActive = json['isActive'] as bool,
      balance = (json['balance'] as num).toDouble(),
      sharePercent = (json['sharePercent'] as num).toDouble();

  /// A partner with nothing yet.
  PartnerCapital.none() : id = '', isActive = true, balance = 0, sharePercent = 0;

  /// The partner.
  final String id;

  /// False once they settled and withdrew.
  final bool isActive;

  /// Their capital.
  final double balance;

  /// Their share of the total, with ten decimals (BR-28).
  final double sharePercent;
}

/// A project's capital (BR-05).
class CapitalFigures {
  /// The figures as the API answers them.
  CapitalFigures.fromJson(Map<String, dynamic> json)
    : total = (json['total'] as num).toDouble(),
      partners = [for (final row in json['partners'] as List<dynamic>) PartnerCapital.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  CapitalFigures.none() : total = 0, partners = const [];

  /// All partners' capital.
  final double total;

  /// The lines the signed-in user may see (BR-31).
  final List<PartnerCapital> partners;

  /// The line of the partner [id]; an empty one when they have none.
  PartnerCapital of(String id) => partners.firstWhere((line) => line.id == id, orElse: PartnerCapital.none);
}

/// A project's capital and shares (UC-044), and the way to enter a movement (UC-042, UC-043). Each change returns an empty string once made, otherwise the word key of the refusal.
class Capital extends ApiObject<CapitalFigures> {
  /// The capital of the project [projectId], seen through [session].
  Capital(Session session, this.projectId) : super(session, '/projects/$projectId/capital', 'capital', (json) => CapitalFigures.fromJson(json! as Map<String, dynamic>), CapitalFigures.none());

  /// The project.
  final String projectId;

  /// Enters a movement.
  Future<String> record(Map<String, Object> body) => change('/projects/$projectId/capital-movements', body);

  /// Carries a balance out of the project [sourceProjectId], as [body] says.
  Future<String> carry(String sourceProjectId, Map<String, Object> body) => change('/projects/$sourceProjectId/capital-movements/carry', body);
}
