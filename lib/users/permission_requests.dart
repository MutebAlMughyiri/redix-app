// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../api_list.dart';
import '../auth/permission.dart';
import '../auth/session.dart';
import '../format/date_format.dart';

/// Where a permission request stands (redix-api #112).
enum PermissionRequestStatus {
  /// Asked, not decided.
  waiting,

  /// Applied as ticking is.
  approved,

  /// Refused, with its reason.
  rejected,
}

/// A person's request to change their own permissions in a project (redix-api #112): what they ask given and taken away, why, when, and where it
/// stands.
class PermissionRequest {
  /// A request as the API sends it.
  PermissionRequest.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      displayName = json['displayName'] as String,
      gives = _permissionsIn(json['gives']),
      takes = _permissionsIn(json['takes']),
      reason = json['reason'] as String,
      askedAt = momentOf(json['askedAt'] as String),
      status = PermissionRequestStatus.values.byName(json['status'] as String),
      rejectionReason = json['rejectionReason'] as String;

  /// No request: someone who never asked.
  PermissionRequest.none()
    : id = '',
      displayName = '',
      gives = const [],
      takes = const [],
      reason = '',
      askedAt = DateTime(1900),
      status = PermissionRequestStatus.approved,
      rejectionReason = '';

  /// The request's id; empty for none.
  final String id;

  /// Who asked, on the managers' list; empty on one's own.
  final String displayName;

  /// The permissions asked for.
  final List<Permission> gives;

  /// The permissions asked to give up.
  final List<Permission> takes;

  /// Why.
  final String reason;

  /// When it was asked.
  final DateTime askedAt;

  /// Where it stands.
  final PermissionRequestStatus status;

  /// Why it was refused; empty otherwise.
  final String rejectionReason;

  /// True for no request.
  bool get isNone => id.isEmpty;

  static List<Permission> _permissionsIn(Object? sent) => [for (final name in sent! as List<dynamic>) Permission.values.byName(name as String)];
}

/// The requests waiting in a project, oldest first, for whoever manages its users to approve or refuse (redix-api #112 R3).
class PermissionRequests extends ApiList<PermissionRequest> {
  /// The requests of the project [projectId], read through [session].
  PermissionRequests(Session session, this.projectId)
    : super(session, '/projects/$projectId/permission-requests', 'permissionRequests', PermissionRequest.fromJson);

  /// The project.
  final String projectId;

  /// Approves [request], applying it as ticking does (R4). Returns an empty string once done, otherwise the word key of the refusal.
  Future<String> approve(PermissionRequest request) => change('/projects/$projectId/permission-requests/${request.id}/approve', {});

  /// Refuses [request] for [reason] (R8); answers as [approve] does.
  Future<String> reject(PermissionRequest request, String reason) => change('/projects/$projectId/permission-requests/${request.id}/reject', {'reason': reason});
}

/// The signed-in person's latest request in a project, waiting or decided (redix-api #112 R1): a list of one, or none.
class MyPermissionRequest extends ApiList<PermissionRequest> {
  /// The person's request in the project [projectId], read through [session].
  MyPermissionRequest(Session session, this.projectId)
    : super(session, '/projects/$projectId/permission-requests/mine', 'permissionRequests', PermissionRequest.fromJson);

  /// The project.
  final String projectId;

  /// The latest request; none when they never asked.
  PermissionRequest get latest => all.firstOrNull ?? PermissionRequest.none();

  /// Asks for [gives] and to give up [takes], for [reason], replacing a request waiting (R7). Returns an empty string once asked, otherwise the word
  /// key of the refusal.
  Future<String> ask(Iterable<Permission> gives, Iterable<Permission> takes, String reason) => change('/projects/$projectId/permission-requests', {
    'gives': [for (final permission in gives) permission.name],
    'takes': [for (final permission in takes) permission.name],
    'reason': reason,
  });

  /// Withdraws the waiting request; answers as [ask] does.
  Future<String> withdraw() => deleteAt('/projects/$projectId/permission-requests/mine');
}
