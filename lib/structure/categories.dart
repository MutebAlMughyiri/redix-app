import '../api_list.dart';
import '../auth/session.dart';
import 'category.dart';

/// A project's categories with their items and subgroups (UC-012), and the one way to change them. Each change returns an empty string once made, otherwise the word key of the refusal.
class Categories extends ApiList<Category> {
  /// The categories of the project [projectId], seen through [session].
  Categories(Session session, this.projectId) : super(session, '/projects/$projectId/categories', 'categories', Category.fromJson);

  /// The project these categories belong to.
  final String projectId;

  /// The item [id]; none while the list is not read yet.
  Item itemOf(String id) => all.expand((category) => category.items).firstWhere((item) => item.id == id, orElse: Item.none);

  /// The name of the category holding the item [id]; empty while the list is not read yet.
  String categoryNameOf(String id) => all.where((category) => category.items.any((item) => item.id == id)).map((category) => category.name).join();

  /// Adds a category named [name] at the end of the list.
  Future<String> addCategory(String name) => change('/projects/$projectId/categories', {'name': name});

  /// Moves the category at [from] to [to], which is its place in the periodic report.
  Future<String> moveCategory(int from, int to) {
    final order = moved(all, from, to);
    return reorder('/projects/$projectId/categories/reorder', {'ids': [for (final category in order) category.id]}, order);
  }

  /// Names [category] [name].
  Future<String> renameCategory(Category category, String name) => change('/projects/$projectId/categories/${category.id}', {'name': name});

  /// Takes [category] and its items out of entry; they stay in the reports.
  Future<String> disableCategory(Category category) => change('/projects/$projectId/categories/${category.id}/disable', {});

  /// Brings the disabled [category] back into entry.
  Future<String> enableCategory(Category category) => change('/projects/$projectId/categories/${category.id}/enable', {});

  /// Adds an item named [name] of [type] at the end of [category].
  Future<String> addItem(Category category, String name, ItemType type) =>
      change('/projects/$projectId/categories/${category.id}/items', {'name': name, 'type': type.name});

  /// Moves the item of [category] at [from] to [to], which is its place in the periodic report.
  Future<String> moveItem(Category category, int from, int to) {
    final items = moved(category.items, from, to);
    return reorder('/projects/$projectId/categories/${category.id}/items/reorder', {'ids': [for (final item in items) item.id]}, [
      for (final each in all) each.id == category.id ? each.withItems(items) : each,
    ]);
  }

  /// Names [item] [name].
  Future<String> renameItem(Item item, String name) => change('/projects/$projectId/items/${item.id}', {'name': name});

  /// Takes [item] out of entry; it stays in the reports.
  Future<String> disableItem(Item item) => change('/projects/$projectId/items/${item.id}/disable', {});

  /// Brings the disabled [item] back into entry.
  Future<String> enableItem(Item item) => change('/projects/$projectId/items/${item.id}/enable', {});

  /// Makes [item] for [type], which the API refuses once it has entries.
  Future<String> changeItemType(Item item, ItemType type) => change('/projects/$projectId/items/${item.id}/type', {'type': type.name});

  /// Moves the named subgroup of [item] at [from] to [to], which is its place in the report; the general one stays first.
  Future<String> moveSubgroup(Item item, int from, int to) {
    final named = moved(item.namedSubgroups, from, to);
    final reordered = item.withNamedSubgroups(named);
    return reorder('/projects/$projectId/items/${item.id}/subgroups/reorder', {'ids': [for (final subgroup in named) subgroup.id]}, [
      for (final each in all) each.withItems([for (final row in each.items) row.id == item.id ? reordered : row]),
    ]);
  }

  /// Removes the [subgroup] of [item], which the API refuses while entries use it.
  Future<String> deleteSubgroup(Item item, Subgroup subgroup) => change('/projects/$projectId/items/${item.id}/subgroups/${subgroup.id}/delete', {});

  /// Adds a subgroup named [name] to [item].
  Future<String> addSubgroup(Item item, String name) => change('/projects/$projectId/items/${item.id}/subgroups', {'name': name});

  /// Names the [subgroup] of [item] [name].
  Future<String> renameSubgroup(Item item, Subgroup subgroup, String name) =>
      change('/projects/$projectId/items/${item.id}/subgroups/${subgroup.id}', {'name': name});
}
