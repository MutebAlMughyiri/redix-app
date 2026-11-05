import 'dart:convert';

/// What a Saudi e-invoice's QR code carries (FR-11): the text is base64 of tag, length and value, one after another, tags 1 to 5 being the seller, its VAT number, the time, the total including VAT and the VAT.
class InvoiceQr {
  InvoiceQr._(this.sellerName, this.vatNumber, this.issuedAt, this.total, this.vat);

  /// No QR code, or none that could be read.
  InvoiceQr.none() : sellerName = '', vatNumber = '', issuedAt = DateTime(1900), total = 0, vat = 0;

  /// The QR code in [text]; [InvoiceQr.none] for anything else, such as an address or a cut-off code. The time stays as the invoice wrote it, so its day is the one printed.
  factory InvoiceQr.parse(String text) {
    final fields = _fieldsOf(text);
    final issuedAt = DateTime.tryParse(fields[3] ?? '');
    final total = double.tryParse(fields[4] ?? '');
    final vat = double.tryParse(fields[5] ?? '');
    final seller = fields[1] ?? '';
    final vatNumber = fields[2] ?? '';
    if (seller.isEmpty || vatNumber.isEmpty || issuedAt == null || total == null || vat == null) {
      return InvoiceQr.none();
    }
    return InvoiceQr._(seller, vatNumber, issuedAt, total, vat);
  }

  /// How far a QR code's VAT may lie from the computed VAT before the screen warns (AC-11.3).
  static const vatTolerance = 0.01;

  static const _lastTag = 5;

  /// The seller's name.
  final String sellerName;

  /// The seller's VAT number.
  final String vatNumber;

  /// When the invoice was issued, in the numbers it wrote.
  final DateTime issuedAt;

  /// The total including VAT.
  final double total;

  /// The VAT.
  final double vat;

  /// True when there is no QR code.
  bool get isNone => vatNumber.isEmpty;

  static Map<int, String> _fieldsOf(String text) {
    final fields = <int, String>{};
    try {
      final bytes = base64.decode(base64.normalize(text.trim()));
      for (var at = 0; at + 2 <= bytes.length && bytes[at] <= _lastTag;) {
        final end = at + 2 + bytes[at + 1];
        fields[bytes[at]] = utf8.decode(bytes.sublist(at + 2, end));
        at = end;
      }
    } on FormatException {
      return const {};
    } on RangeError {
      return const {};
    }
    return fields;
  }
}
