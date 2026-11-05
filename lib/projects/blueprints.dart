import '../api_list.dart';
import '../auth/session.dart';

/// An engineering blueprint kept for the project or one of its units (UC-064).
class Blueprint {
  /// A blueprint as the API answers it.
  Blueprint.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      unitName = json['unitName'] as String,
      attachmentId = json['attachmentId'] as String,
      fileName = json['fileName'] as String,
      contentType = json['contentType'] as String,
      uploadedAt = DateTime.parse(json['uploadedAt'] as String);

  /// The blueprint.
  final String id;

  /// What it shows.
  final String title;

  /// The unit it is for; empty for the whole project.
  final String unitName;

  /// Its file.
  final String attachmentId;

  /// The file's name.
  final String fileName;

  /// What the file is.
  final String contentType;

  /// When it was kept.
  final DateTime uploadedAt;
}

/// A project's blueprints, the whole project's first, then each unit's (UC-064), and the way to keep and remove one. Each change returns an empty string once made, otherwise the word key of the refusal.
class Blueprints extends ApiList<Blueprint> {
  /// The blueprints of the project [projectId], seen through [session].
  Blueprints(Session session, this.projectId) : super(session, '/projects/$projectId/blueprints', 'blueprints', Blueprint.fromJson);

  /// The project.
  final String projectId;

  /// Keeps the kept file [attachmentId] as the blueprint [title] of the unit [unitId], or of the whole project when that is empty.
  Future<String> add(String attachmentId, String unitId, String title) =>
      change('/projects/$projectId/blueprints', {'attachmentId': attachmentId, 'title': title, if (unitId.isNotEmpty) 'unitId': unitId});

  /// Takes [blueprint] off the list; its file stays kept.
  Future<String> remove(Blueprint blueprint) => change('/projects/$projectId/blueprints/${blueprint.id}/delete', {});
}
