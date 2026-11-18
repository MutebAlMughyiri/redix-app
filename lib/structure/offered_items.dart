// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../api_list.dart';
import '../auth/session.dart';
import 'category.dart';

/// What an entry of one type may choose from, by category. The API owns what is on offer (AC-05.3, AC-38.1).
class OfferedItems extends ApiList<Category> {
  /// The items of the project [projectId] on offer for [type], seen through [session].
  OfferedItems(Session session, String projectId, ItemType type) : super(session, '/projects/$projectId/categories/offered?itemType=${type.name}', 'categories', Category.fromJson);
}
