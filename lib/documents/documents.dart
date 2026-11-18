// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../api_list.dart';
import '../attachments/picked_file.dart';
import '../auth/session.dart';
import '../format/date_format.dart';

/// A document kept for the project (UC-064): any file under a name, in a group when one was given.
class Document {
  /// A document as the API answers it.
  Document.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      group = json['group'] as String,
      attachmentId = json['attachmentId'] as String,
      fileName = json['fileName'] as String,
      contentType = json['contentType'] as String,
      uploadedAt = momentOf(json['uploadedAt'] as String);

  /// The document.
  final String id;

  /// What it is.
  final String name;

  /// The group it is listed under; empty for none.
  final String group;

  /// Its file.
  final String attachmentId;

  /// The file's name.
  final String fileName;

  /// What the file is.
  final String contentType;

  /// When it was kept.
  final DateTime uploadedAt;
}

/// A project's documents, those in no group first, then each group (UC-064), and the way to keep and remove one. Each change returns an empty string once made, otherwise the word key of the refusal.
class Documents extends ApiList<Document> {
  /// The documents of the project [projectId], seen through [session].
  Documents(Session session, this.projectId) : super(session, '/projects/$projectId/documents', 'documents', Document.fromJson);

  /// The project.
  final String projectId;

  /// The groups the project's documents are in, each once, in the list's order.
  List<String> get groups => {for (final document in all) if (document.group.isNotEmpty) document.group}.toList();

  /// Keeps [file] as the document [name], in [group], or in none when that is empty.
  Future<String> add(PickedFile file, String name, String group) => sendFile('/projects/$projectId/documents', file.name, file.bytes, fields: {'name': name, 'group': group});

  /// Takes [document] off the list; its file stays kept.
  Future<String> remove(Document document) => deleteAt('/projects/$projectId/documents/${document.id}');
}
