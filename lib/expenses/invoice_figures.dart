/// An invoice's figures while they are being typed. The API computes the ones kept, from what was typed (BR-13); these only show what it will answer, the same way.
class InvoiceFigures {
  /// The figures of [amount], which [includesVat] or not, less [discount], at [vatRate] as a fraction.
  factory InvoiceFigures.of({required double amount, required bool includesVat, required double discount, required double vatRate}) {
    final afterDiscount = (includesVat ? amount / (1 + vatRate) : amount) - discount;
    final vat = afterDiscount * vatRate;
    return InvoiceFigures._(afterDiscount, vat, afterDiscount + vat);
  }

  InvoiceFigures._(this.afterDiscount, this.vat, this.total);

  /// These figures as a credit note holds them, each one negative (BR-18).
  InvoiceFigures get negated => InvoiceFigures._(-afterDiscount, -vat, -total);

  /// The amount before VAT, after the discount.
  final double afterDiscount;

  /// The VAT of this row.
  final double vat;

  /// The amount after the discount, with VAT.
  final double total;
}
