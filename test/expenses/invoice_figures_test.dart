import 'package:flutter_test/flutter_test.dart';
import 'package:redix/expenses/invoice_figures.dart';
import 'package:redix/format/number_format.dart';

void main() {
  test('AC-08.1: 6,000.00 including VAT shows 5,217.39, 782.61 and 6,000.00', () {
    final figures = InvoiceFigures.of(amount: 6000, includesVat: true, discount: 0, vatRate: 0.15);

    expect(formatMoney(figures.afterDiscount), '5,217.39');
    expect(formatMoney(figures.vat), '782.61');
    expect(formatMoney(figures.total), '6,000.00');
  });

  test('AC-08.2: 2,569.90 before VAT has VAT 385.485 and a total of 2,955.385, shown as 2,955.39', () {
    final figures = InvoiceFigures.of(amount: 2569.90, includesVat: false, discount: 0, vatRate: 0.15);

    expect(figures.vat, closeTo(385.485, 0.00001));
    expect(figures.total, closeTo(2955.385, 0.00001));
    expect(formatMoney(figures.total), '2,955.39');
  });

  test('AC-08.3: 1,000 before VAT with a discount of 100 shows 900, 135 and 1,035', () {
    final figures = InvoiceFigures.of(amount: 1000, includesVat: false, discount: 100, vatRate: 0.15);

    expect(formatMoney(figures.afterDiscount), '900.00');
    expect(formatMoney(figures.vat), '135.00');
    expect(formatMoney(figures.total), '1,035.00');
  });

  test('a discount on an amount including VAT comes off the amount before VAT', () {
    final figures = InvoiceFigures.of(amount: 1150, includesVat: true, discount: 100, vatRate: 0.15);

    expect(formatMoney(figures.total), '1,035.00');
  });

  test('the rate is what the project says, and 0 leaves the amount whole', () {
    expect(formatMoney(InvoiceFigures.of(amount: 1000, includesVat: false, discount: 0, vatRate: 0.05).vat), '50.00');
    expect(formatMoney(InvoiceFigures.of(amount: 6000, includesVat: true, discount: 0, vatRate: 0).total), '6,000.00');
  });

  group('NFR-04: an amount rounds to two decimals, half up', () {
    test('a stored 2,955.385 shows 2,955.39, though the double just under it would not', () => expect(formatMoney(2955.385), '2,955.39'));
    test('a stored 385.485 shows 385.49', () => expect(formatMoney(385.485), '385.49'));
    test('a stored 1.3350 shows 1.34', () => expect(formatMoney(1.335), '1.34'));
    test('a stored 1.3349 shows 1.33', () => expect(formatMoney(1.3349), '1.33'));
    test('a carry reaches the whole riyals', () => expect(formatMoney(999.995), '1,000.00'));
    test('a negative shows in brackets', () => expect(formatMoney(-120.405), '(120.41)'));
    test('nothing shows 0.00', () => expect(formatMoney(0), '0.00'));
    test('the largest amount shows whole', () => expect(formatMoney(999999999.99), '999,999,999.99'));
  });
}
