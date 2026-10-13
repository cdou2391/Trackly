/// Writes one CSV field (RFC 4180): wrapped in quotes, with inner quotes
/// doubled, when it holds a comma, quote, or line break.
String csvField(String value) {
  if (value.contains(RegExp('[",\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Whether a spreadsheet would run [value] as a formula, or would once a
/// protective apostrophe has been put in front of it: it starts with `=`, `+`,
/// `-`, `@`, a tab or a carriage return, after any number of apostrophes.
bool _needsGuard(String value) {
  var i = 0;
  while (i < value.length && value[i] == "'") {
    i++;
  }
  return i < value.length && '=+-@\t\r'.contains(value[i]);
}

/// Makes user-typed text safe to open in a spreadsheet.
///
/// Excel, Sheets and Numbers run a cell that starts with `=`, `+`, `-` or `@`
/// (or a tab or carriage return) as a formula, so a subscription named
/// `=HYPERLINK(...)` could do something when the export is opened. A leading
/// apostrophe makes the cell plain text; spreadsheets do not show it.
///
/// Text that already starts with apostrophes before such a character (`'=x`)
/// gets one more, so that [csvTextRestore] can tell it apart.
String csvText(String value) => _needsGuard(value) ? "'$value" : value;

/// The exact inverse of [csvText]: `csvTextRestore(csvText(x)) == x` for every
/// text, which is what makes an exported file import back unchanged. One
/// leading apostrophe is removed only when what follows would itself have
/// been guarded; an apostrophe anywhere else is the person's own and stays.
String csvTextRestore(String value) {
  if (value.startsWith("'") && _needsGuard(value.substring(1))) {
    return value.substring(1);
  }
  return value;
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
