// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/expenses/invoice_qr.dart';

import 'made_up_qr.dart';

void main() {
  test('AC-11.1: a QR code gives the seller, VAT number, date and time, total and VAT', () {
    final qr = InvoiceQr.parse(madeUpQr());

    expect(qr.isNone, isFalse);
    expect(qr.sellerName, 'شركة البواني للتجارة');
    expect(qr.vatNumber, '310823353100003');
    expect(qr.issuedAt.year, 2026);
    expect(qr.issuedAt.month, 10);
    expect(qr.issuedAt.day, 26);
    expect(qr.issuedAt.hour, 14);
    expect(qr.issuedAt.minute, 25);
    expect(qr.total, 6000);
  });

  test('the day stays the one the invoice wrote, however late it was', () {
    final qr = InvoiceQr.parse(madeUpQr(time: '2026-10-26T23:50:00Z'));

    expect(qr.issuedAt.day, 26);
  });

  test('a newer code carrying tags after the fifth reads the same', () {
    final longer = [...base64.decode(madeUpQr()), 6, 200, ...List.filled(200, 65), 9, 3, 1, 2, 3];

    expect(InvoiceQr.parse(base64.encode(longer)).total, 6000);
  });

  test('a code with no padding reads the same', () {
    final text = madeUpQr(seller: 'شركة').replaceAll('=', '');

    expect(InvoiceQr.parse(text).sellerName, 'شركة');
  });

  test('AC-11.2: what is not an e-invoice QR code is no QR code', () {
    for (final text in ['', 'https://example.com/invoice', 'ليس رمزاً', 'AQID', base64.encode([1, 200, 65]), base64.encode(utf8.encode('plain text'))]) {
      expect(InvoiceQr.parse(text).isNone, isTrue, reason: text);
    }
  });

  test('AC-11.2: a code missing a field, or with an amount or a date that is none, is no QR code', () {
    expect(InvoiceQr.parse(tlv({1: 'شركة', 2: '310823353100003', 3: '2026-10-26T14:25:00Z', 4: '6000.00'})).isNone, isTrue);
    expect(InvoiceQr.parse(madeUpQr(total: 'كثير')).isNone, isTrue);
    expect(InvoiceQr.parse(madeUpQr(vat: '')).isNone, isTrue);
    expect(InvoiceQr.parse(madeUpQr(time: 'أمس')).isNone, isTrue);
    expect(InvoiceQr.parse(madeUpQr(seller: '')).isNone, isTrue);
    expect(InvoiceQr.parse(madeUpQr(vatNumber: '')).isNone, isTrue);
  });
}
