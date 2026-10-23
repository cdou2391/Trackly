import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trackly/core/utils/format_utils.dart';

void main() {
  test('formats common currencies with symbols', () {
    expect(formatMoney(15.49, 'USD', locale: 'en'), r'$15.49');
    expect(formatMoney(8, 'EUR', locale: 'en'), '€8.00');
    expect(formatMoney(1012.44, 'USD', locale: 'en'), r'$1,012.44');
  });

  test(
    'uses the currency code for others, without decimals when none apply',
    () {
      expect(formatMoney(30000, 'RWF', locale: 'en'), 'RWF 30,000');
    },
  );

  test('short date follows the locale', () async {
    await initializeDateFormatting('en_GB');
    expect(formatShortDate(DateTime(2026, 10, 18), locale: 'en'), 'Oct 18');
    expect(formatShortDate(DateTime(2026, 10, 18), locale: 'en_GB'), '18 Oct');
  });

  group('formatCompactMoney', () {
    test('keeps the symbol of the common currencies', () {
      expect(formatCompactMoney(47.82, 'USD', locale: 'en'), r'$48');
      expect(formatCompactMoney(12, 'EUR', locale: 'en'), '€12');
      expect(formatCompactMoney(5, 'GBP', locale: 'en'), '£5');
    });

    test('keeps a decimal for small amounts', () {
      expect(formatCompactMoney(3.29, 'USD', locale: 'en'), r'$3.3');
      expect(formatCompactMoney(0.5, 'USD', locale: 'en'), r'$0.5');
    });

    test('shortens thousands and millions', () {
      expect(formatCompactMoney(1500, 'USD', locale: 'en'), r'$1.5K');
      expect(formatCompactMoney(22900, 'RWF', locale: 'en'), '22.9K');
      expect(formatCompactMoney(2400000, 'RWF', locale: 'en'), '2.4M');
    });

    test('has no symbol for other currencies (the caller names it)', () {
      expect(formatCompactMoney(300, 'RWF', locale: 'en'), '300');
    });

    test('zero is plain', () {
      expect(formatCompactMoney(0, 'USD', locale: 'en'), r'$0');
    });
  });
}
