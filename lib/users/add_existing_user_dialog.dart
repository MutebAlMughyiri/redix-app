// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'users.dart';
import 'users_screen.dart';

/// Adds someone who already has a login to this project, by their exact username, so a manager never sees another project's people.
class AddExistingUserDialog extends StatefulWidget {
  /// The dialog adding to [users].
  const AddExistingUserDialog({super.key, required this.users});

  /// The project's people.
  final Users users;

  @override
  State<AddExistingUserDialog> createState() => _AddExistingUserDialogState();
}

class _AddExistingUserDialogState extends State<AddExistingUserDialog> {
  final _username = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.usersAddExisting,
      saveLabel: words.usersAdd,
      onSave: () => widget.users.addExisting(_username.text),
      children: [
        TextField(
          key: UsersScreen.existingUsernameKey,
          controller: _username,
          autocorrect: false,
          decoration: InputDecoration(labelText: words.usersUsername),
        ),
      ],
    );
  }
}
