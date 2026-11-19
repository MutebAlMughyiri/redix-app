// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../partners/partner.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'permission_tick.dart';

/// Every permission of a project as a tick, in the API's order, each group under its heading (Permission.groupWordKey): the two capital ticks under رأس المال, the two report ticks under
/// التقارير, and under رأس مال شركاء محددين, while it is ticked, the project's
/// partners to tick (BR-31, redix-api #106). The one list the Permissions screen, صلاحياتي and the new-person form draw.
class PermissionTicks extends StatelessWidget {
  /// The ticks, each keyed [keyOf], ticked as [holds] says, changed through [onChangedOf]; the [partners] under the chosen-capital tick ticked as [chosen] says, changed through [onChooseOf].
  /// A function that answers null leaves that tick read-only.
  /// Only the permissions [shows] keeps are drawn, every one unless a search narrows them (صلاحياتي, the owner, 12 Nov 2026).
  const PermissionTicks({
    super.key,
    required this.keyOf,
    required this.holds,
    required this.onChangedOf,
    required this.partners,
    required this.chosen,
    required this.onChooseOf,
    this.shows = showsAll,
  });

  /// The key of each permission's tick, which each screen names.
  final Key Function(Permission permission) keyOf;

  /// Whether the permission is held.
  final bool Function(Permission permission) holds;

  /// What ticking the permission does; null where it cannot change.
  final ValueChanged<bool>? Function(Permission permission) onChangedOf;

  /// The partners that can be chosen.
  final List<Partner> partners;

  /// Whether the partner is chosen.
  final bool Function(Partner partner) chosen;

  /// What ticking the partner does; null where it cannot change.
  final ValueChanged<bool>? Function(Partner partner) onChooseOf;

  /// Whether the permission is drawn.
  final bool Function(Permission permission) shows;

  /// Every permission.
  static bool showsAll(Permission permission) => true;

  /// The heading over the two capital ticks.
  static const capitalGroupKey = Key('permissions.capitalGroup');

  /// The heading over the two report ticks (redix-api #131).
  static const reportsGroupKey = Key('permissions.reportsGroup');

  /// The tick of the partner [id], under رأس مال شركاء محددين.
  static Key partnerKey(String id) => Key('permissions.partner.$id');

  Widget _partnerTick(Partner partner) {
    final key = partnerKey(partner.id);
    final change = onChooseOf(partner);
    return Padding(
      key: key,
      padding: const EdgeInsetsDirectional.only(start: 24),
      child: Card.outlined(
        key: key.card,
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          key: key.body,
          controlAffinity: ListTileControlAffinity.leading,
          value: chosen(partner),
          title: Text(partner.name, key: key.title),
          onChanged: change == null ? null : (ticked) => change(ticked ?? false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final shown = Permission.inAProject.where(shows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (place, permission) in shown.indexed) ...[
          if (permission.groupWordKey.isNotEmpty && (place == 0 || shown[place - 1].groupWordKey != permission.groupWordKey))
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(words.text(permission.groupWordKey), key: Key(permission.groupWordKey), style: Theme.of(context).textTheme.titleSmall),
            ),
          PermissionTick(key: keyOf(permission), permission: permission, value: holds(permission), onChanged: onChangedOf(permission)),
          if (permission == Permission.seeChosenCapital && holds(permission)) ...partners.map(_partnerTick),
        ],
      ],
    );
  }
}
