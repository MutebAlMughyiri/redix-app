// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

/// The non-empty [parts] of a line, joined by a middle dot, the one way a row writes its details (deep review, 9 Nov 2026).
String partsLine(Iterable<String> parts) => parts.where((part) => part.isNotEmpty).join(' · ');
