// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

/// A word with places for values, such as "Transferred {0} from {1} to {2}": the one way to fill them (redix-app #89).
extension WordFill on String {
  /// This word with [values] in its places: the first in `{0}`, the next in `{1}`, and so on.
  String fill(List<String> values) {
    var filled = this;
    for (final (index, value) in values.indexed) {
      filled = filled.replaceAll('{$index}', value);
    }
    return filled;
  }
}
