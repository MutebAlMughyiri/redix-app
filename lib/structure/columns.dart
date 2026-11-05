import '../api_list.dart';
import '../auth/session.dart';
import 'category.dart';
import 'item_column.dart';

/// The columns of one item, or of a project's default template for one type of item (UC-013), and the one way to change them. Both sit at the same shape of address; [applyToAll] means
/// something only to the template. Each change returns an empty string once made, otherwise the word key of the refusal.
class Columns extends ApiList<ItemColumn> {
  /// The columns at the API [_path], seen through [session].
  Columns(Session session, this._path) : super(session, _path, 'columns', ItemColumn.fromJson);

  final String _path;

  /// The API's address of the columns of the item [itemId] of the project [projectId].
  static String itemPath(String projectId, String itemId) => '/projects/$projectId/items/$itemId/columns';

  /// The API's address of the default template of the project [projectId] for [type].
  static String templatePath(String projectId, ItemType type) => '/projects/$projectId/default-columns/${type.name}';

  /// Adds a column at the end, with the [options] of a list.
  Future<String> add(String name, ColumnDataType dataType, {required bool isRequired, required bool showInReports, required List<String> options, required bool applyToAll}) => change(_path, {
    'name': name,
    'dataType': dataType.name,
    'isRequired': isRequired,
    'showInReports': showInReports,
    'options': options,
    'applyToAllItems': applyToAll,
  });

  /// Changes [column], and adds [newOptions] to its choices; its type never changes, and no choice is taken away.
  Future<String> edit(ItemColumn column, String name, {required bool isRequired, required bool showInReports, List<String> newOptions = const [], required bool applyToAll}) => change('$_path/${column.id}', {
    'name': name,
    'isRequired': isRequired,
    'showInReports': showInReports,
    if (newOptions.isNotEmpty) 'newOptions': newOptions,
    'applyToAllItems': applyToAll,
  });

  /// Deletes [column]: it leaves entry, and its values stay.
  Future<String> delete(ItemColumn column, {required bool applyToAll}) => change('$_path/${column.id}/delete', {'applyToAllItems': applyToAll});

  /// Moves the column at [from] to [to].
  Future<String> move(int from, int to, {required bool applyToAll}) {
    final order = moved(all, from, to);
    return reorder('$_path/reorder', {'ids': [for (final column in order) column.id], 'applyToAllItems': applyToAll}, order);
  }
}
