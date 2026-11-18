// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

/// A project waiting for the admin, as the API answers it: what is needed to decide, and nothing more.
class RegisteredProject {
  /// The project the API describes in [json].
  RegisteredProject.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      startDate = DateTime.parse(json['startDate'] as String),
      units = (json['units'] as List<dynamic>).cast<String>(),
      managerName = json['managerName'] as String,
      managerUsername = json['managerUsername'] as String,
      managerMobile = json['managerMobile'] as String,
      description = json['description'] as String;

  /// The project's id.
  final String id;

  /// The project's name.
  final String name;

  /// The day it started.
  final DateTime startDate;

  /// The names of its units, in order.
  final List<String> units;

  /// The name of whoever registered it.
  final String managerName;

  /// Their username.
  final String managerUsername;

  /// Their mobile; empty when none.
  final String managerMobile;

  /// What the project is, as its manager wrote it; empty for none.
  final String description;
}
