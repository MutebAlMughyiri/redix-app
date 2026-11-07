import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/part_keys.dart';
import '../words/words.dart';
import 'notifications.dart';
import 'notifications_screen.dart';

/// The way to what the person was told, counting what they have not seen.
class NotificationsBell extends StatefulWidget {
  /// The bell of [notifications].
  const NotificationsBell({super.key, required this.notifications});

  /// The button.
  static const buttonKey = Key('notifications.bell');

  /// What the person was told.
  final Notifications notifications;

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  @override
  void initState() {
    super.initState();
    widget.notifications.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifications,
      builder: (context, _) {
        final unread = widget.notifications.unread;
        return IconButton(
          key: NotificationsBell.buttonKey,
          icon: Badge.count(key: NotificationsBell.buttonKey.label, count: unread, isLabelVisible: unread > 0, child: Icon(Icons.notifications_outlined, key: NotificationsBell.buttonKey.icon)),
          tooltip: Words.of(context).notificationsTitle,
          onPressed: () => context.push(NotificationsScreen.path),
        );
      },
    );
  }
}
