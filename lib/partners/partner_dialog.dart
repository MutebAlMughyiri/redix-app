import 'package:flutter/material.dart';

import '../projects/member_picker.dart';
import '../projects/members.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'partner.dart';
import 'partners.dart';
import 'partners_screen.dart';

/// Asks for a partner's name and their login.
class PartnerDialog extends StatefulWidget {
  /// The dialog changing [partner], or adding one when it is [Partner.none], through [partners], choosing the login among [members].
  const PartnerDialog({super.key, required this.partner, required this.partners, required this.members});

  /// The partner this dialog changes.
  final Partner partner;

  /// The way to change them.
  final Partners partners;

  /// The people who can be this partner's login.
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
          decoration: InputDecoration(labelText: words.partnersName, border: const OutlineInputBorder()),
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
