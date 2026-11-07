/// The amount of a kept invoice as a person typed it, for changing it (UC-033). The API keeps the amount before VAT with four decimals (BR-13), but a person types
/// two at most: an amount typed before VAT comes back as it was, and one typed with VAT, whose amount before VAT then has more than two decimals, comes back with VAT.
/// Either way, sending it again computes the same figures.
class TypedAmount {
  const TypedAmount._(this.amount, this.includesVat);

  /// The amount of [invoice], as the API answers an entry's invoice.
  factory TypedAmount.of(Map<String, dynamic> invoice) {
    final beforeVat = (invoice['amountBeforeDiscount'] as num).abs().toDouble();
    final afterDiscount = (invoice['amountAfterDiscount'] as num).toDouble();
    if (beforeVat == double.parse(beforeVat.toStringAsFixed(2)) || afterDiscount == 0) {
      return TypedAmount._(beforeVat, false);
    }
    final rate = (invoice['vat'] as num) / afterDiscount;
    return TypedAmount._(double.parse((beforeVat * (1 + rate)).toStringAsFixed(2)), true);
  }

  /// The amount, with at most two decimals.
  final double amount;

  /// Whether [amount] includes VAT.
  final bool includesVat;
}
