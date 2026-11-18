// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api.dart';
import '../auth/session.dart';

/// Keeps on the phone what a project's screens read, so that an entry can be entered with no network (UC-030, FR-16).
class ProjectSync {
  /// The sync seen through [_session].
  ProjectSync(this._session);

  final Session _session;

  /// Keeps what changed in the project [projectId] since the last sync. Without a network nothing changes, and the copies stay.
  Future<void> refresh(String projectId) async {
    final stampKey = '/projects/$projectId/stamp';
    try {
      final since = await _session.copyOf(stampKey);
      final response = await _session.read('/projects/$projectId/sync?since=$since');
      if (response.statusCode != 200) {
        return;
      }
      final answer = jsonOf(response) as Map<String, dynamic>;
      final lists = answer['lists'] as Map<String, dynamic>;
      for (final MapEntry(key: address, value: list) in lists.entries) {
        await _session.keepCopy(address, jsonEncode(list));
      }
      await _session.keepCopy(stampKey, answer['stamp'] as String);
    } on Exception catch (error) {
      debugPrint('Project not synced: $error');
    }
  }
}
