import 'package:drift/drift.dart';

/// Stores a calendar date as `YYYY-MM-DD` text.
///
/// Due dates are calendar days, not moments in time, so storing them as UTC
/// timestamps could shift them by a day when the timezone changes. ISO text
/// also sorts chronologically, so `ORDER BY` and range queries work directly.
class DateOnlyConverter extends TypeConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromSql(String fromDb) {
    final parts = fromDb.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected YYYY-MM-DD', fromDb);
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  String toSql(DateTime value) => formatDateOnly(value);
}

/// `YYYY-MM-DD` for the local calendar date of [value].
String formatDateOnly(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
