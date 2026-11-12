import 'package:flutter/material.dart';

import '../words/words.dart';
import 'act_once.dart';
import 'app_color.dart';
import 'part_keys.dart';
import 'refusal_snack_bar.dart';

/// The one way a row is removed (Muteb, 8 Nov 2026, redix-api #102), and the one frame of a row that can be: an outlined card. Where [mayRemove] is true a red bar lies inside
/// the card along its end edge (redix-app #88), and the row is swiped from that edge toward its start, which turns with the language, past 40% of its width; red with a bin and
/// the word Remove shows behind it while it moves. The swipe does not remove: the row asks in place, حذف and إلغاء inside it, never a window over the screen (Muteb, 12 Nov
/// 2026, redix-api #119); إلغاء, or a tap anywhere else, puts it back. حذف removes it through [onRemove]; a refusal shows and the row stays. Where the removal can be undone,
/// the bar at the bottom offers تراجع through [onUndo] for [undoTime]. Where [mayRemove] is false the card has no bar and does not move.
class SwipeToRemove extends StatefulWidget {
  /// The swipe of the row keyed [rowKey], removing it through [onRemove] while [mayRemove], and bringing it back through [onUndo] where it can be.
  const SwipeToRemove({super.key, required this.rowKey, required this.mayRemove, required this.onRemove, this.onUndo = noUndo, this.side = BorderSide.none, required this.child});

  /// The row's own key; the swipe's is its `swipe` part, and what shows behind it is that part's icon and label; the question is its `question` part, its buttons its
  /// `confirm` and `cancel` parts.
  final Key rowKey;

  /// Whether the signed-in user may remove it now.
  final bool mayRemove;

  /// Removes it; answers an empty string once removed, otherwise the word key of the refusal.
  final Future<String> Function() onRemove;

  /// Brings it back once removed, answering as [onRemove] does; [noUndo] for a row whose removal cannot be undone, which offers no تراجع.
  final Future<String> Function() onUndo;

  /// The row.
  final Widget child;

  /// The side of the row's card: [BorderSide.none] for the card's own outline, or the color its row stands in, as an entry's status (redix-app #90).
  final BorderSide side;

  /// The red bar's width, in logical pixels (redix-app #88, D2).
  static const barWidth = 4.0;

  /// How long the bar at the bottom offers تراجع (redix-api #119).
  static const undoTime = Duration(seconds: 6);

  /// What a row whose removal cannot be undone offers: nothing.
  static Future<String> noUndo() async => '';

  @override
  State<SwipeToRemove> createState() => _SwipeToRemoveState();
}

class _SwipeToRemoveState extends State<SwipeToRemove> {
  var _asking = false;

  void _ask(bool asking) => setState(() => _asking = asking);

  /// A list that lost a row hands this state to the row after it, which must not inherit the question.
  @override
  void didUpdateWidget(SwipeToRemove oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowKey != widget.rowKey) {
      _asking = false;
    }
  }

  Future<void> _remove() async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final undo = widget.onUndo;
    final refusal = await showRefusalOf(context, widget.onRemove());
    if (refusal.isNotEmpty) {
      if (mounted) {
        _ask(false);
      }
      return;
    }
    if (undo != SwipeToRemove.noUndo) {
      showMessage(messenger, words, 'swipe.removed', actionLabel: words.commonUndo, duration: SwipeToRemove.undoTime, onAction: () async {
        final undone = await undo();
        if (undone.isNotEmpty) {
          showMessage(messenger, words, undone);
        }
      });
    }
  }

  Widget _question(Words words) => TapRegion(
    onTapOutside: (_) => _ask(false),
    child: Padding(
      key: widget.rowKey.question,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(child: Text(words.swipeQuestion, key: widget.rowKey.question.label)),
          ActOnce(builder: (once) => FilledButton(
            key: widget.rowKey.confirm,
            style: FilledButton.styleFrom(backgroundColor: AppColor.refusal.of(context)),
            onPressed: once(_remove),
            child: Text(words.swipeRemove, key: widget.rowKey.confirm.label),
          )),
          TextButton(key: widget.rowKey.cancel, onPressed: () => _ask(false), child: Text(words.commonCancel, key: widget.rowKey.cancel.label)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final rowKey = widget.rowKey;
    final swipe = rowKey.swipe;
    final framed = Card.outlined(
      key: rowKey.card,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: widget.side == BorderSide.none ? BorderSide(color: AppColor.frame.of(context)) : widget.side),
      child: Stack(
        children: [
          if (_asking) _question(words) else widget.child,
          if (widget.mayRemove && !_asking) PositionedDirectional(key: rowKey.bar, end: 0, top: 0, bottom: 0, width: SwipeToRemove.barWidth, child: ColoredBox(color: AppColor.refusal.of(context))),
        ],
      ),
    );
    if (!widget.mayRemove || _asking) {
      return framed;
    }
    return Dismissible(
      key: swipe,
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      confirmDismiss: (_) async {
        _ask(true);
        return false;
      },
      background: Container(
        color: AppColor.refusalSurface.of(context),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(Icons.delete_outline, key: swipe.icon, color: AppColor.onRefusalSurface.of(context)),
            Text(words.swipeRemove, key: swipe.label, style: TextStyle(color: AppColor.onRefusalSurface.of(context), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: framed,
    );
  }
}
