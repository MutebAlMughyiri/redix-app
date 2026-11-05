import '../api_list.dart';
import '../auth/session.dart';
import 'notification_row.dart';

/// What the signed-in person was told (UC-036).
class Notifications extends ApiList<NotificationRow> {
  /// What the person signed in through [session] was told.
  Notifications(Session session) : super(session, '/notifications', 'notifications', NotificationRow.fromJson);

  /// How many were not seen yet.
  int get unread => all.where((row) => !row.isRead).length;

  /// Marks [row] as seen.
  Future<String> markRead(NotificationRow row) => change('/notifications/${row.id}/read', {});
}
