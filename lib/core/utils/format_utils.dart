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
