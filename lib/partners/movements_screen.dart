import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../entries/reverse_sheet.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'capital.dart';
import 'capital_movement.dart';
import 'capital_movements.dart';
import '../ui/list_search.dart';
import '../words/word_fill.dart';
import '../format/parts_line.dart';

/// One partner's movements (UC-044), each with its receipt, and for whoever decides entries a way to reverse it (BR-11).
class MovementsScreen extends StatefulWidget {
  /// The movements of the partner named [partnerName] in [project].
  const MovementsScreen({super.key, required this.project, required this.partnerName, required this.movements, required this.capital});

  /// The address of the screen.
  static const path = '/projects/:projectId/partners/:partnerId/movements';

  /// The address of the movements of the partner [partnerId], named [name].
  static String pathOf(String projectId, String partnerId, String name) => Uri(path: '/projects/$projectId/partners/$partnerId/movements', queryParameters: {'name': name}).toString();

  /// The row of the movement [id].
  static Key rowKey(String id) => Key('movements.row.$id');

  /// The button opening the receipt of the movement [id].
  static Key receiptKey(String id) => Key('movements.receipt.$id');

  /// The button reversing the movement [id].
  static Key reverseKey(String id) => Key('movements.reverse.$id');

  /// The project.
  final Project project;

  /// Whose they are.
  final String partnerName;

  /// The movements.
  final CapitalMovements movements;

  /// The capital they change.
  final Capital capital;

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  @override
  void initState() {
    super.initState();
    widget.movements.loadOnOpen();
  }

  Future<String> _reverse(CapitalMovement movement, String reason) async {
    final refusal = await widget.movements.reverse(movement, reason);
    if (refusal.isEmpty) {
      await widget.capital.load();
    }
    return refusal;
  }

  Widget _row(CapitalMovement movement) {
    final words = Words.of(context);
    final project = widget.project;
    final parts = [
      words.text('capital.${movement.type}'),
      formatDate(movement.date),
      movement.accountName,
      if (movement.isReversed) words.capitalReversed,
    ];
    return Card.outlined(
      key: MovementsScreen.rowKey(movement.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: MovementsScreen.rowKey(movement.id).body,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
        title: Text(movement.description.isEmpty ? words.text('capital.${movement.type}') : movement.description, key: MovementsScreen.rowKey(movement.id).title),
        subtitle: Text(parts.join(' · '), key: MovementsScreen.rowKey(movement.id).subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatMoney(movement.amount), key: MovementsScreen.rowKey(movement.id).trailing, style: Theme.of(context).textTheme.titleSmall),
            if (movement.attachmentId.isNotEmpty)
              IconButton(
                key: MovementsScreen.receiptKey(movement.id),
                icon: Icon(Icons.receipt_long_outlined, key: MovementsScreen.receiptKey(movement.id).icon),
                tooltip: words.capitalReceiptAttached,
                onPressed: () => context.push(AttachmentScreen.pathOf(project.id, movement.attachmentId, fileName: movement.fileName), extra: movement.contentType),
              ),
            if (project.mayApproveEntries && !movement.isReversed)
              IconButton(
                key: MovementsScreen.reverseKey(movement.id),
                icon: Icon(Icons.undo, key: MovementsScreen.reverseKey(movement.id).icon),
                tooltip: words.capitalReverse,
                onPressed: () => ReverseSheet.show(context, (reason) => _reverse(movement, reason)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.capitalMovements, subject: widget.partnerName)),
      body: ApiListBody<CapitalMovement>(
        list: widget.movements,
        emptyText: words.capitalNoMovements,
        search: ListSearch(
          hint: words.commonSearchIn.fill([words.capitalMovements]),
          textOf: (movement) => partsLine([words.text('capital.${movement.type}'), movement.description, movement.accountName, formatDate(movement.date), searchableAmount(movement.amount)]),
        ),
        itemBuilder: _row,
      ),
    );
  }
}
