// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../projects/member_picker.dart';
import '../projects/members.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'partner.dart';
import 'partners.dart';
import 'partners_screen.dart';

/// Asks for a partner's name and their own account (حساب الشريك), which only says whose account they are. Their table is the project's one capital item (redix-api #109), and who sees
/// them is ticked on people's permissions (redix-api #106).
class PartnerDialog extends StatefulWidget {
  /// The dialog changing [partner], or adding one when it is [Partner.none], through [partners], choosing their account among the project's [members].
  const PartnerDialog({super.key, required this.partner, required this.partners, required this.members});

  /// The partner this dialog changes.
  final Partner partner;

  /// The way to change them.
  final Partners partners;

  /// The project's people, one of whom may be this partner.
  final Members members;

  @override
  State<PartnerDialog> createState() => _PartnerDialogState();
}

class _PartnerDialogState extends State<PartnerDialog> {
  late final _name = TextEditingController(text: widget.partner.name);
  late var _userId = widget.partner.userId;

  bool get _isNew => widget.partner.id.isEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: _isNew ? words.partnersNew : words.partnersEdit,
      saveLabel: _isNew ? words.partnersNew : words.partnersSave,
      onSave: () => _isNew ? widget.partners.add(_name.text, _userId) : widget.partners.edit(widget.partner, _name.text, _userId),
      children: [
        TextField(
          key: PartnersScreen.partnerNameKey,
          controller: _name,
          autofocus: _isNew,
          decoration: InputDecoration(labelText: words.partnersName),
        ),
        const SizedBox(height: 16),
        MemberPicker(
          key: PartnersScreen.loginKey,
          members: widget.members,
          label: words.partnersLogin,
          nobody: words.partnersNoLogin,
          userId: _userId,
          currentId: widget.partner.userId,
          currentName: widget.partner.userName,
          onChanged: (userId) => setState(() => _userId = userId),
        ),
        const SizedBox(height: 8),
        Text(words.partnersLoginHint, key: PartnersScreen.loginHintKey, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
