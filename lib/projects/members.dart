// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../api_list.dart';
import '../auth/session.dart';
import 'member.dart';

/// The active people of one project, for choosing who holds something in it.
class Members extends ApiList<Member> {
  /// The people of the project [projectId], seen through [session].
  Members(Session session, String projectId) : super(session, '/projects/$projectId/members', 'projects', Member.fromJson);
}
