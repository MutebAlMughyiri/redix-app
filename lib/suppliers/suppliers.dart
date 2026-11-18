// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../api_list.dart';
import '../auth/session.dart';
import '../format/number_format.dart';
import 'supplier.dart';
import 'supplier_search.dart';

/// What a person fills in about a supplier: its [name], its [vatNumber] and [mobile], each empty for none, and the id of its default item, empty for none.
typedef SupplierFields = ({String name, String vatNumber, String mobile, String defaultItemId});

/// A project's supplier register (UC-017), and the one way to change it. Each change returns an empty string once made, otherwise the word key of the refusal.
class Suppliers extends ApiList<Supplier> {
  /// The register of the project [projectId], seen through [session].
  Suppliers(Session session, this.projectId) : search = SupplierSearch(session, projectId), super(session, '/projects/$projectId/suppliers', 'suppliers', Supplier.fromJson);

  /// The project this register belongs to.
  final String projectId;

  /// What an entry may pick from this register.
  final SupplierSearch search;

  /// The supplier the last add made; none when it made none.
  Supplier get added => lastAnswer.containsKey('id') ? Supplier.fromJson(lastAnswer) : Supplier.none();

  /// The supplier holding the VAT number the last change was refused for; none otherwise.
  Supplier get holder => lastAnswer.containsKey('existing') ? Supplier.fromJson(lastAnswer['existing'] as Map<String, dynamic>) : Supplier.none();

  Map<String, Object> _bodyOf(SupplierFields fields) => {
    'name': fields.name,
    'vatNumber': westernDigits(fields.vatNumber.trim()),
    if (fields.mobile.isNotEmpty) 'mobile': westernDigits(fields.mobile),
    if (fields.defaultItemId.isNotEmpty) 'defaultItemId': fields.defaultItemId,
  };

  /// Adds a supplier with [fields].
  Future<String> add(SupplierFields fields) => change('/projects/$projectId/suppliers', _bodyOf(fields));

  /// Changes [supplier] to [fields].
  Future<String> edit(Supplier supplier, SupplierFields fields) => put('/projects/$projectId/suppliers/${supplier.id}', _bodyOf(fields));

  /// Takes [supplier] out of entry; it stays in the reports.
  Future<String> disable(Supplier supplier) => change('/projects/$projectId/suppliers/${supplier.id}/disable', {});

  /// Brings the disabled [supplier] back into entry.
  Future<String> enable(Supplier supplier) => change('/projects/$projectId/suppliers/${supplier.id}/enable', {});
}
