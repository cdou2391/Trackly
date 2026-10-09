import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trackly/core/utils/format_utils.dart';

void main() {
  test('formats common currencies with symbols', () {
    expect(formatMoney(15.49, 'USD', locale: 'en'), r'$15.49');
    expect(formatMoney(8, 'EUR', locale: 'en'), '€8.00');
    expect(formatMoney(1012.44, 'USD', locale: 'en'), r'$1,012.44');
  });

  test('uses the currency code for others, without decimals when none apply',
      () {
    expect(formatMoney(30000, 'RWF', locale: 'en'), 'RWF 30,000');
  });

  test('short date follows the locale', () async {
    await initializeDateFormatting('en_GB');
    expect(formatShortDate(DateTime(2026, 10, 18), locale: 'en'), 'Oct 18');
    expect(formatShortDate(DateTime(2026, 10, 18), locale: 'en_GB'), '18 Oct');
  });
}
