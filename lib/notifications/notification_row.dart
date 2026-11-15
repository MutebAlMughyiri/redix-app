import '../format/date_format.dart';

/// Something a person was told (UC-036): its words come from [kind], in their language.
class NotificationRow {
  /// A notification as the API sends it.
  NotificationRow.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      projectId = json['projectId'] as String,
      projectName = json['projectName'] as String,
      entryId = json['entryId'] as String,
      at = momentOf(json['at'] as String),
      isRead = json['isRead'] as bool;

  /// The notification's id.
  final String id;

  /// What happened, the end of its word key.
  final String kind;

  /// The project it is about.
  final String projectId;

  /// Its name.
  final String projectName;

  /// The entry tapping it opens.
  final String entryId;

  /// When it happened.
  final DateTime at;

  /// True once seen.
  final bool isRead;

  /// True when it asks for a decision.
  bool get asksForDecision => kind == 'entrySubmitted';

  /// True when it is about the project itself, not one of its entries.
  bool get isAboutProject => kind.startsWith('project');
}
