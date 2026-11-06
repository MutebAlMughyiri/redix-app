import '../api_list.dart';
import '../auth/session.dart';

/// What a table of an item's sheet prints, as the API names it.
enum ItemTableKind {
  /// The item's general group, named after the item.
  general,

  /// A named subgroup.
  subgroup,

  /// A contract's payments, named after its contractor.
  contract,
}

/// One table of an item's sheet (AC-46.8), as the API answers it.
class ItemTable {
  /// The table the API describes in [json].
  ItemTable.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = ItemTableKind.values.byName(json['kind'] as String),
      name = json['name'] as String,
      count = json['count'] as int;

  /// The subgroup or contract it prints.
  final String id;

  /// What it prints.
  final ItemTableKind kind;

  /// The item's name for its general table, the subgroup's, or the contractor's.
  final String name;

  /// How many approved entries it holds.
  final int count;

  /// True for a subgroup a person named, which they may rename and remove; the general table and a contract's are not theirs to change here.
  bool get isNamedSubgroup => kind == ItemTableKind.subgroup;
}

/// An item's tables in the order its sheet prints them, and the one way to change them: add, rename and remove a subgroup, and move any table. Each change returns an empty string
/// once made, otherwise the word key of the refusal.
class ItemTables extends ApiList<ItemTable> {
  /// The tables of the item [itemId] of the project [projectId], seen through [session].
  ItemTables(Session session, this.projectId, this.itemId) : super(session, '/projects/$projectId/items/$itemId/tables', 'categories', ItemTable.fromJson);

  /// The project.
  final String projectId;

  /// The item.
  final String itemId;

  /// Moves the table at [from] to [to], which is its place in the item's sheet.
  Future<String> move(int from, int to) {
    final order = moved(all, from, to);
    return reorder('/projects/$projectId/items/$itemId/tables/reorder', {'ids': [for (final table in order) table.id]}, order);
  }

  /// Adds a subgroup named [name], after the item's other tables.
  Future<String> addSubgroup(String name) => change('/projects/$projectId/items/$itemId/subgroups', {'name': name});

  /// Names the subgroup [table] [name].
  Future<String> renameSubgroup(ItemTable table, String name) => change('/projects/$projectId/items/$itemId/subgroups/${table.id}', {'name': name});

  /// Removes the subgroup [table], which the API refuses while entries use it.
  Future<String> deleteSubgroup(ItemTable table) => change('/projects/$projectId/items/$itemId/subgroups/${table.id}/delete', {});
}
