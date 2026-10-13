/// Why a file could not be read as CSV at all.
enum CsvProblem { unclosedQuote, strayQuote, tooManyRows }

class CsvFormatException implements Exception {
  const CsvFormatException(this.problem, {this.line});

  final CsvProblem problem;

  /// The line the problem starts on, counting from 1.
  final int? line;

  @override
  String toString() => 'CsvFormatException($problem, line: $line)';
}

/// One record: its fields, and the line it starts on (from 1, counting the
/// header), so a problem can be reported where the person can find it.
class CsvRow {
  const CsvRow(this.line, this.fields);

  final int line;
  final List<String> fields;
}

class CsvTable {
  const CsvTable({
    required this.headers,
    required this.rows,
    required this.delimiter,
  });

  /// Column names, trimmed and lower-cased.
  final List<String> headers;
  final List<CsvRow> rows;
  final String delimiter;
}

/// The largest number of data rows read from one file.
const maxCsvRows = 50000;

/// Reads CSV text (RFC 4180 and the usual spreadsheet variations).
///
/// - A byte order mark is dropped.
/// - The separator is the one the header line uses most: a comma, a semicolon
///   (spreadsheets in many languages) or a tab.
/// - Fields may be quoted, with `""` for a quote, and may hold line breaks.
/// - Lines end with CRLF, LF or CR. Blank lines are skipped.
///
/// Throws [CsvFormatException] for a quote that never closes, a quote in the
/// middle of an unquoted field, or too many rows. A file with no header line
/// gives an empty table.
CsvTable parseCsv(String input, {int maxRows = maxCsvRows}) {
  final text = input.startsWith('﻿') ? input.substring(1) : input;
  final delimiter = _sniffDelimiter(text);

  final rows = <CsvRow>[];
  var fields = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldWasQuoted = false;
  var line = 1;
  var recordLine = 1;
  var quoteLine = 1;

  void endField() {
    fields.add(field.toString());
    field.clear();
    fieldWasQuoted = false;
  }

  void endRecord() {
    endField();
    final blank = fields.length == 1 && fields.first.trim().isEmpty;
    if (!blank) {
      rows.add(CsvRow(recordLine, fields));
      // The header is row 0, so rows beyond [maxRows] data rows are too many.
      if (rows.length > maxRows + 1) {
        throw const CsvFormatException(CsvProblem.tooManyRows);
      }
    }
    fields = <String>[];
  }

  var i = 0;
  while (i < text.length) {
    final char = text[i];

    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        // After a closing quote only a separator or a line end may follow.
        if (i < text.length) {
          final next = text[i];
          if (next != delimiter && next != '\n' && next != '\r') {
            throw CsvFormatException(CsvProblem.strayQuote, line: line);
          }
        }
        continue;
      }
      if (char == '\n') line++;
      field.write(char);
      i++;
      continue;
    }

    if (char == '"') {
      // A quote may only open a field.
      if (field.isNotEmpty || fieldWasQuoted) {
        throw CsvFormatException(CsvProblem.strayQuote, line: line);
      }
      inQuotes = true;
      fieldWasQuoted = true;
      quoteLine = line;
      i++;
    } else if (char == delimiter) {
      endField();
      i++;
    } else if (char == '\n' || char == '\r') {
      endRecord();
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      i++;
      line++;
      recordLine = line;
    } else {
      field.write(char);
      i++;
    }
  }

  if (inQuotes) {
    throw CsvFormatException(CsvProblem.unclosedQuote, line: quoteLine);
  }
  // A last record without a line end.
  if (field.isNotEmpty || fieldWasQuoted || fields.isNotEmpty) endRecord();

  if (rows.isEmpty) {
    return CsvTable(headers: const [], rows: const [], delimiter: delimiter);
  }
  final headers = [for (final h in rows.first.fields) h.trim().toLowerCase()];
  return CsvTable(
    headers: headers,
    rows: rows.skip(1).toList(),
    delimiter: delimiter,
  );
}

/// The separator the first line uses most, outside quotes. A comma on a tie.
String _sniffDelimiter(String text) {
  final counts = {',': 0, ';': 0, '\t': 0};
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (!inQuotes) {
      if (char == '\n' || char == '\r') break;
      if (counts.containsKey(char)) counts[char] = counts[char]! + 1;
    }
  }
  var best = ',';
  for (final entry in counts.entries) {
    if (entry.value > counts[best]!) best = entry.key;
  }
  return best;
}
