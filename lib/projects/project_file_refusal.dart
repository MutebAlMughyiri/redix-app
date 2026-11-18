// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../format/parts_line.dart';
import '../words/word_fill.dart';
import '../words/words.dart';

/// Whose rule refused a part of a project file, as the API names it, each knowing the start of its words' keys: a refusal shows its owner's own word (redix-api #132 D14).
enum ProjectFileOwner {
  /// The file itself, read as a project: an account the project lacks, a file named in a row, a choice the lists do not hold, a report the project issued already.
  file('projects.loadFile'),

  /// Add entry, which every row goes through (AC-53.4).
  entry('expenses'),

  /// The structure: a category, an item or a subgroup.
  structure('categories'),

  /// A contract.
  contract('contracts'),

  /// A partner.
  partner('partners'),

  /// A supplier of the register.
  supplier('suppliers'),

  /// A payment method.
  paymentMethod('paymentMethods'),

  /// The reconciliation of the actual balances.
  reconciliation('reconciliations');

  const ProjectFileOwner(this.wordPrefix);

  /// The start of the keys of this owner's words.
  final String wordPrefix;
}

/// One refusal of a project file's load, as the API answers it (UC-071, AC-53.5): where it is by the file's own names and the row's place, whose rule refused it, and why.
class ProjectFileRefusal {
  /// The refusal the API describes in [json].
  ProjectFileRefusal.fromJson(Map<String, dynamic> json)
    : item = json['item'] as String,
      table = json['table'] as String,
      row = json['row'] as int,
      owner = ProjectFileOwner.values.byName(json['owner'] as String),
      code = json['code'] as String,
      value = json['value'] as String,
      column = json['column'] as String;

  /// The file's item; empty when the refusal is not inside one.
  final String item;

  /// The file's table; empty when the refusal is not inside one.
  final String table;

  /// The row's place in its table, counted from 1 as the sheet's «#» counts it; 0 for the part itself.
  final int row;

  /// Whose rule refused it.
  final ProjectFileOwner owner;

  /// Its code.
  final String code;

  /// The value it names, an account's or a choice's; empty when it names none.
  final String value;

  /// The name of the column it names; empty when it names none.
  final String column;

  /// Where it is, as the file and its workbook name it: the item, the table and «#» with the row's place (redix-api #132, the Refused screen).
  String get place => partsLine([item, table, if (row > 0) '#$row']);

  /// Why, in [words]: its owner's word for its code, with the value and the column it names in its places.
  String reasonIn(Words words) => words.text('${owner.wordPrefix}.$code').fill([value, column]);
}
