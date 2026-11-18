// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

/// A way a project pays, such as شبكة, as the API answers it.
class PaymentMethod {
  /// The payment method the API describes in [json].
  PaymentMethod.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      isActive = json['isActive'] as bool,
      accountIds = [for (final id in json['accountIds'] as List<dynamic>) id as String];

  /// No method: what a new method's dialog starts from.
  PaymentMethod.none() : id = '', name = '', isActive = true, accountIds = const [];

  /// The method's id.
  final String id;

  /// The method's name, as it was typed.
  final String name;

  /// False once disabled: it disappears from entry and stays on the entries that used it.
  final bool isActive;

  /// The accounts it pays from, ticked in its dialog (redix-app #109).
  final List<String> accountIds;

  /// Whether it pays from the account [accountId].
  bool paysFrom(String accountId) => accountIds.contains(accountId);
}
