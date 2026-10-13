import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/export/application/csv.dart';

void main() {
  group('csvField', () {
    test('leaves plain text alone', () {
      expect(csvField('Netflix'), 'Netflix');
      expect(csvField(''), '');
      expect(csvField('Adobe Creative Cloud'), 'Adobe Creative Cloud');
    });

    test('quotes text with a comma', () {
      expect(csvField('Rent, flat 2'), '"Rent, flat 2"');
    });

    test('doubles quotes inside quoted text', () {
      expect(csvField('The "Pro" plan'), '"The ""Pro"" plan"');
    });

    test('quotes text with a line break', () {
      expect(csvField('line one\nline two'), '"line one\nline two"');
      expect(csvField('a\r\nb'), '"a\r\nb"');
    });
  });

  group('csvText (spreadsheet formulas)', () {
    test('defuses text a spreadsheet would run as a formula', () {
      expect(csvText('=SUM(A1:A9)'), "'=SUM(A1:A9)");
      expect(csvText('+1 555 0100'), "'+1 555 0100");
      expect(csvText('-Gym'), "'-Gym");
      expect(csvText('@home'), "'@home");
      expect(csvText('\tcell'), "'\tcell");
      expect(csvText('\rcell'), "'\rcell");
    });

    test('leaves ordinary text alone', () {
      expect(csvText('Netflix'), 'Netflix');
      expect(csvText('Gym - monthly'), 'Gym - monthly');
      expect(csvText('1Password'), '1Password');
      expect(csvText(''), '');
    });
  });

  group('buildCsv', () {
    test('writes the header and rows with CRLF line ends', () {
      final csv = buildCsv(
        ['a', 'b'],
        [
          ['1', 'x,y'],
          ['2', 'z'],
        ],
      );
      expect(csv, 'a,b\r\n1,"x,y"\r\n2,z\r\n');
    });

    test('with no rows is just the header', () {
      expect(buildCsv(['a', 'b'], const []), 'a,b\r\n');
    });
  });
}
