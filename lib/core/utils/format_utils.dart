import 'package:intl/intl.dart';

const _currencySymbols = {'USD': r'$', 'EUR': '€', 'GBP': '£'};

/// "$15.49", "€8.00" or "RWF 30,000". Decimal digits follow the currency.
String formatMoney(double amount, String currencyCode, {String? locale}) {
  final symbol = _currencySymbols[currencyCode] ?? '$currencyCode ';
  return NumberFormat.currency(
    locale: locale,
    name: currencyCode,
    symbol: symbol,
  ).format(amount);
}

/// Locale-aware short date, for example "18 Oct" or "Oct 18".
String formatShortDate(DateTime date, {String? locale}) {
  return DateFormat.MMMd(locale).format(date);
}

/// Locale-aware date with the year, for example "18 Oct 2025" or "Oct 18, 2025".
String formatMediumDate(DateTime date, {String? locale}) {
  return DateFormat.yMMMd(locale).format(date);
}

/// "$", "€", "£" for the common currencies, otherwise the code itself.
String currencySymbol(String currencyCode) =>
    _currencySymbols[currencyCode] ?? currencyCode;

/// A short amount for tight spots such as chart bars: "$47", "$3.3", "22.9K",
/// "1.2M". The symbol is kept for the common currencies; for the others the
/// caller shows the currency code separately.
String formatCompactMoney(
  double amount,
  String currencyCode, {
  String? locale,
}) {
  final symbol = _currencySymbols[currencyCode] ?? '';
  final abs = amount.abs();

  final String number;
  if (abs >= 1000) {
    number = (NumberFormat.compact(
      locale: locale,
    )..maximumFractionDigits = 1).format(amount);
  } else if (abs > 0 && abs < 10) {
    // Small amounts keep one decimal so $3.29 is not shown as $3.
    number =
        (NumberFormat.decimalPattern(locale)
              ..minimumFractionDigits = 0
              ..maximumFractionDigits = 1)
            .format(amount);
  } else {
    number = (NumberFormat.decimalPattern(
      locale,
    )..maximumFractionDigits = 0).format(amount);
  }
  return '$symbol$number';
}
