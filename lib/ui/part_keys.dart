import 'package:flutter/widgets.dart';

/// The keys of the parts inside a keyed element: its label, icon, title, subtitle and the field it is drawn as. Every element and label has a key a test finds it by, never
/// its position (Muteb, 7 Nov 2026); a part's key is made from its element's, so the two cannot drift. It reads a widget's own `key` too, which a widget that has parts
/// requires.
extension PartKeys on Key? {
  /// The key of the element's label.
  Key get label => ValueKey((this, 'label'));

  /// The key of the element's icon.
  Key get icon => ValueKey((this, 'icon'));

  /// The key of the element's title.
  Key get title => ValueKey((this, 'title'));

  /// The key of the element's subtitle.
  Key get subtitle => ValueKey((this, 'subtitle'));

  /// The key of the field an element is drawn as, such as the picker field a table picker shows.
  Key get field => ValueKey((this, 'field'));

  /// The key of what the element shows at its end, such as a row's amount or chevron.
  Key get trailing => ValueKey((this, 'trailing'));

  /// The key of the element's body, such as the row a card holds.
  Key get body => ValueKey((this, 'body'));

  /// The key of the card that holds the element.
  Key get card => ValueKey((this, 'card'));

  /// The key of the bar that draws the element's share.
  Key get bar => ValueKey((this, 'bar'));

  /// The key of the swipe that removes the element (redix-api #102).
  Key get swipe => ValueKey((this, 'swipe'));
}
