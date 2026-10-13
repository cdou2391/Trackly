import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:trackly/core/error/error_scrubber.dart';

void main() {
  group('scrubErrorText', () {
    test('drops the values a failed statement quotes', () {
      const text =
          'SqliteException(1555): while executing statement, UNIQUE '
          'constraint failed: recurring_items.id\n'
          '  Causing statement: INSERT INTO recurring_items (id, name, notes) '
          'VALUES (?, ?, ?), parameters: abc-123, Netflix, my secret note';
      final scrubbed = scrubErrorText(text);

      expect(scrubbed, isNot(contains('Netflix')));
      expect(scrubbed, isNot(contains('secret')));
      expect(scrubbed, isNot(contains('abc-123')));
      expect(scrubbed, endsWith(', parameters: [removed]'));
    });

    test('keeps the statement and the reason, which help fix the bug', () {
      const text =
          'SqliteException(19): constraint failed\n'
          '  Causing statement: UPDATE payments SET amount = ? WHERE id = ?, '
          'parameters: 15.5, p1';
      final scrubbed = scrubErrorText(text);

      expect(scrubbed, contains('SqliteException(19): constraint failed'));
      expect(scrubbed, contains('UPDATE payments SET amount = ? WHERE id = ?'));
    });

    test('removes values that span several lines and text after them', () {
      const text =
          'boom, parameters: line one\nline two, with commas\nCaused by: x';
      expect(scrubErrorText(text), 'boom, parameters: [removed]');
    });

    test('leaves other text unchanged', () {
      const text = 'Bad state: No element';
      expect(scrubErrorText(text), text);
      expect(scrubErrorText(''), '');
    });

    test('scrubs a real SqliteException from the sqlite3 library', () {
      final db = sqlite3.openInMemory()
        ..execute('CREATE TABLE t (id TEXT PRIMARY KEY, name TEXT)')
        ..execute("INSERT INTO t VALUES ('a', 'Spotify')");
      Object? error;
      try {
        // The same id again, with a value the user typed.
        db.prepare('INSERT INTO t VALUES (?, ?)').execute([
          'a',
          'Private note',
        ]);
      } catch (e) {
        error = e;
      }
      db.close();

      expect(error, isA<SqliteException>());
      expect(error.toString(), contains('Private note'));
      expect(scrubErrorText(error.toString()), isNot(contains('Private note')));
    });
  });

  group('scrubSentryEvent', () {
    test('scrubs every exception in a chain and the message', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'SqliteException',
            value: 'bad, parameters: Netflix, 9.99',
          ),
          SentryException(
            type: 'DriftWrappedException',
            value: 'wrapped: bad, parameters: Netflix, 9.99',
          ),
          SentryException(type: 'StateError', value: 'Bad state'),
        ],
        message: SentryMessage(
          'failed, parameters: Gym',
          template: 'failed, parameters: %s',
          params: ['Gym'],
        ),
      );

      final scrubbed = scrubSentryEvent(event, Hint());

      expect(scrubbed, same(event));
      expect(scrubbed.exceptions![0].value, 'bad, parameters: [removed]');
      expect(
        scrubbed.exceptions![1].value,
        'wrapped: bad, parameters: [removed]',
      );
      expect(scrubbed.exceptions![2].value, 'Bad state');
      expect(scrubbed.message!.formatted, 'failed, parameters: [removed]');
      expect(scrubbed.message!.template, 'failed, parameters: [removed]');
      expect(scrubbed.message!.params, isNull);
    });

    test('handles an event with nothing to scrub', () {
      final event = SentryEvent();
      expect(scrubSentryEvent(event, Hint()), same(event));
    });

    test('handles an exception without a value', () {
      final event = SentryEvent(
        exceptions: [SentryException(type: 'X', value: null)],
      );
      expect(scrubSentryEvent(event, Hint()).exceptions!.single.value, isNull);
    });
  });
}
