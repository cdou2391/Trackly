/// Writes one CSV field (RFC 4180): wrapped in quotes, with inner quotes
/// doubled, when it holds a comma, quote, or line break.
String csvField(String value) {
  if (value.contains(RegExp('[",\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Makes user-typed text safe to open in a spreadsheet.
///
/// Excel, Sheets and Numbers run a cell that starts with `=`, `+`, `-` or `@`
/// (or a tab or carriage return) as a formula, so a subscription named
/// `=HYPERLINK(...)` could do something when the export is opened. A leading
/// apostrophe makes the cell plain text; spreadsheets do not show it.
String csvText(String value) {
  if (value.isEmpty) return value;
  return '=+-@\t\r'.contains(value[0]) ? "'$value" : value;
}

/// A whole CSV document: the header, then the rows, with CRLF line ends.
String buildCsv(List<String> header, Iterable<List<String>> rows) {
  final buffer = StringBuffer();
  for (final row in [header, ...rows]) {
    buffer
      ..writeAll(row.map(csvField), ',')
      ..write('\r\n');
  }
  return buffer.toString();
}
