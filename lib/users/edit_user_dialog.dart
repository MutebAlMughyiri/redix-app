import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'user.dart';
import 'users.dart';
import 'users_screen.dart';

/// Corrects a user's name and mobile. A username never changes.
class EditUserDialog extends StatefulWidget {
  /// The dialog changing [user] through [users].
  const EditUserDialog({super.key, required this.user, required this.users});

  /// The user to change.
  final User user;

  /// The way to change them.
  final Users users;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final _name = TextEditingController(text: widget.user.displayName);
  late final _mobile = TextEditingController(text: widget.user.mobile);

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.usersEdit,
      saveLabel: words.usersSave,
      onSave: () => widget.users.edit(widget.user, _name.text, _mobile.text),
      children: [
        TextField(
          key: UsersScreen.editNameKey,
          controller: _name,
          decoration: InputDecoration(labelText: words.usersName),
        ),
        const SizedBox(height: 16),
        TextField(
          key: UsersScreen.editMobileKey,
          controller: _mobile,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: words.usersMobile),
        ),
      ],
    );
  }
}
