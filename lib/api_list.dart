import 'package:flutter/foundation.dart';

import 'api_object.dart';
import 'auth/session.dart';

/// A copy of [list] with the row at [from] moved to [to], as a drag ends.
List<E> moved<E>(List<E> list, int from, int to) {
  final order = [...list];
  order.insert(to, order.removeAt(from));
  return order;
}

/// A list the API owns, as it last answered, and the way to change it.
abstract class ApiList<T> extends ApiObject<List<T>> {
  /// The list at the API [path], made from JSON by [fromJson], whose word keys start with [wordPrefix].
  ApiList(Session session, String path, String wordPrefix, T Function(Map<String, dynamic>) fromJson)
    : super(session, path, wordPrefix, (json) => [for (final item in json! as List<dynamic>) fromJson(item as Map<String, dynamic>)], <T>[]);

  /// Every item, in the order the API gives.
  List<T> get all => value;

  /// Adds the page the API [pagePath] answers after the items shown, for a list read a page at a time (redix-app #89). Returns an empty string once added, otherwise
  /// the word key saying it could not be read; what is shown stays. A page that arrives once the list reads elsewhere, as a new search makes it, is dropped.
  @protected
  Future<String> loadMore(String pagePath) async {
    final readFrom = pointedAt;
    try {
      final page = await readAt(pagePath);
      if (pointedAt == readFrom) {
        show([...all, ...page]);
      }
      return '';
    } on Exception catch (error) {
      debugPrint('$pagePath not read: $error');
      return loadFailedKey;
    }
  }

  /// Shows [order] at once, so what was dragged stays where it was dropped, and sends the change to the API [path]. Whatever is refused, or never arrives, goes back to what the API holds.
  /// Returns an empty string once changed, otherwise the word key of the refusal.
  @protected
  Future<String> reorder(String path, Map<String, Object> body, List<T> order) async {
    show(order);
    final refusal = await change(path, body);
    if (refusal.isNotEmpty) {
      await load();
    }
    return refusal;
  }
}
