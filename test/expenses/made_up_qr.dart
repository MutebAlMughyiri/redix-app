// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';

/// The text of a QR code holding [fields] by tag, as a Saudi e-invoice writes it: base64 of tag, length and value.
String tlv(Map<int, String> fields) => base64.encode([
  for (final MapEntry(key: tag, value: text) in fields.entries) ...[tag, utf8.encode(text).length, ...utf8.encode(text)],
]);

/// The QR code of a made-up invoice.
String madeUpQr({String seller = 'شركة البواني للتجارة', String vatNumber = '310823353100003', String time = '2026-10-26T14:25:00Z', String total = '6000.00', String vat = '782.61'}) =>
    tlv({1: seller, 2: vatNumber, 3: time, 4: total, 5: vat});
