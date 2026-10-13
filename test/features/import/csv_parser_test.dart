import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/import/application/csv_parser.dart';

List<List<String>> fieldsOf(CsvTable t) => [for (final r in t.rows) r.fields];

void main() {
  group('basics', () {
    test('reads a header and rows', () {
      final t = parseCsv('Name,Amount\r\nNetflix,15.49\r\nSpotify,9.99\r\n');
      expect(t.headers, ['name', 'amount']);
      expect(fieldsOf(t), [
        ['Netflix', '15.49'],
        ['Spotify', '9.99'],
      ]);
      expect(t.delimiter, ',');
    });

    test('headers are trimmed and lower-cased', () {
      expect(parseCsv(' Name , AMOUNT \nx,1').headers, ['name', 'amount']);
    });

    test('accepts CRLF, LF and CR line ends', () {
      for (final eol in ['\r\n', '\n', '\r']) {
        final t = parseCsv('a,b${eol}1,2${eol}3,4');
        expect(fieldsOf(t), [
          ['1', '2'],
          ['3', '4'],
        ], reason: 'line end ${eol.codeUnits}');
      }
    });

    test('a last row without a line end is kept', () {
      expect(fieldsOf(parseCsv('a\n1\n2')), [
        ['1'],
        ['2'],
      ]);
    });

    test('blank lines are skipped', () {
      expect(fieldsOf(parseCsv('a,b\n\n1,2\n   \n\n3,4\n')), [
        ['1', '2'],
        ['3', '4'],
      ]);
    });

    test('drops a UTF-8 byte order mark', () {
      expect(parseCsv('﻿name,amount\nx,1').headers, ['name', 'amount']);
    });

    test('empty text and a header-only file give no rows', () {
      expect(parseCsv('').rows, isEmpty);
      expect(parseCsv('').headers, isEmpty);
      expect(parseCsv('name,amount\r\n').rows, isEmpty);
      expect(parseCsv('name,amount\r\n').headers, ['name', 'amount']);
    });

    test('empty cells stay empty', () {
      expect(fieldsOf(parseCsv('a,b,c\n1,,3\n,,')), [
        ['1', '', '3'],
        ['', '', ''],
      ]);
    });
  });

  group('quotes', () {
    test('a quoted field may hold commas, quotes and line breaks', () {
      final t = parseCsv(
        'name,notes\r\n"Rent, flat ""2""","line one\r\nline two"\r\nNext,x\r\n',
      );
      expect(fieldsOf(t), [
        ['Rent, flat "2"', 'line one\r\nline two'],
        ['Next', 'x'],
      ]);
    });

    test('an empty quoted field is empty, not a blank line', () {
      expect(fieldsOf(parseCsv('a,b\n"",x')), [
        ['', 'x'],
      ]);
    });

    test('line numbers count the header and lines inside quotes', () {
      final t = parseCsv('a,b\n1,"two\nlines"\n3,4\n');
      expect(t.rows.map((r) => r.line), [2, 4]);
    });

    test('a quote that never closes is reported where it opened', () {
      expect(
        () => parseCsv('a,b\n1,2\n3,"oops\n4,5'),
        throwsA(
          isA<CsvFormatException>()
              .having((e) => e.problem, 'problem', CsvProblem.unclosedQuote)
              .having((e) => e.line, 'line', 3),
        ),
      );
    });

    test('a quote in the middle of a field is refused', () {
      expect(
        () => parseCsv('a,b\n12"3,4'),
        throwsA(
          isA<CsvFormatException>()
              .having((e) => e.problem, 'problem', CsvProblem.strayQuote)
              .having((e) => e.line, 'line', 2),
        ),
      );
    });

    test('text after a closing quote is refused', () {
      expect(
        () => parseCsv('a,b\n"x"y,2'),
        throwsA(
          isA<CsvFormatException>().having(
            (e) => e.problem,
            'problem',
            CsvProblem.strayQuote,
          ),
        ),
      );
    });
  });

  group('separators', () {
    test('uses a semicolon when the header does', () {
      final t = parseCsv('name;amount\nNetflix;15,49\n');
      expect(t.delimiter, ';');
      expect(fieldsOf(t), [
        ['Netflix', '15,49'],
      ]);
    });

    test('uses a tab when the header does', () {
      final t = parseCsv('name\tamount\nNetflix\t15.49');
      expect(t.delimiter, '\t');
      expect(fieldsOf(t), [
        ['Netflix', '15.49'],
      ]);
    });

    test('separators inside quotes in the header do not count', () {
      final t = parseCsv('"a;b;c;d",e\n1,2');
      expect(t.delimiter, ',');
      expect(t.headers, ['a;b;c;d', 'e']);
    });

    test('a single column is read with a comma', () {
      expect(parseCsv('name\nx').delimiter, ',');
    });
  });

  group('limits', () {
    test('too many rows is refused', () {
      final text = 'a\n${List.filled(11, 'x').join('\n')}';
      expect(
        () => parseCsv(text, maxRows: 10),
        throwsA(
          isA<CsvFormatException>().having(
            (e) => e.problem,
            'problem',
            CsvProblem.tooManyRows,
          ),
        ),
      );
      expect(
        parseCsv('a\n${List.filled(10, 'x').join('\n')}', maxRows: 10).rows,
        hasLength(10),
      );
    });
  });
}
