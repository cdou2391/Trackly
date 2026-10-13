import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/export/application/data_export.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item(
  String name, {
  String? id,
  double amount = 10,
  String currency = 'USD',
  BillingFrequency frequency = BillingFrequency.monthly,
  int interval = 1,
  ItemStatus status = ItemStatus.active,
  RecurringItemType type = RecurringItemType.subscription,
  DateTime? trialEnd,
  bool reminders = true,
  int reminderDays = 3,
  int reminderMinute = defaultReminderMinuteOfDay,
  String? category,
  String? notes,
}) {
  return RecurringItem(
    id: id ?? name,
    name: name,
    type: type,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    interval: interval,
    startDate: DateTime(2026, 1, 5),
    nextDueDate: DateTime(2026, 10, 20),
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    remindersEnabled: reminders,
    reminderDaysBefore: reminderDays,
    reminderMinuteOfDay: reminderMinute,
    categoryId: category,
    notes: notes,
    createdAt: DateTime(2026, 2, 3, 14, 30),
    updatedAt: _now,
  );
}

Payment payment(
  String id,
  String itemId, {
  required DateTime due,
  DateTime? paid,
  PaymentStatus status = PaymentStatus.paid,
  double amount = 10,
  String currency = 'USD',
}) {
  return Payment(
    id: id,
    recurringItemId: itemId,
    amount: amount,
    currencyCode: currency,
    dueDate: due,
    paidDate: paid,
    status: status,
    createdAt: DateTime(2026, 9, 1, 8),
  );
}

/// The file's text, checking it starts with the byte order mark.
String text(ExportFile file) {
  expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF], reason: 'byte order mark');
  return utf8.decode(file.bytes.skip(3).toList());
}

List<ExportFile> export({
  List<RecurringItem> items = const [],
  List<Payment> payments = const [],
  Map<String, String> categories = const {},
}) => buildExportFiles(
  items: items,
  payments: payments,
  categoryNames: categories,
  now: DateTime(2026, 10, 13, 23, 45),
);

void main() {
  test('makes a subscriptions file and a payments file named by date', () {
    final files = export(items: [item('Netflix')]);
    expect(files.map((f) => f.name), [
      'trackly-subscriptions-2026-10-13.csv',
      'trackly-payments-2026-10-13.csv',
    ]);
  });

  test('the headers are stable', () {
    final files = export();
    expect(
      text(files[0]),
      'name,type,status,amount,currency,frequency,every,start_date,'
      'next_due_date,free_trial,trial_end_date,reminders,'
      'reminder_days_before,reminder_time,category,notes,added_on,id\r\n',
    );
    expect(
      text(files[1]),
      'subscription,due_date,paid_date,status,amount,currency,'
      'subscription_id,id\r\n',
    );
  });

  group('subscriptions file', () {
    String row(RecurringItem i, {Map<String, String> categories = const {}}) =>
        text(export(items: [i], categories: categories)[0]).split('\r\n')[1];

    test('writes every field of an ordinary subscription', () {
      expect(
        row(
          item(
            'Netflix',
            amount: 15.5,
            category: 'ent',
            notes: 'Family plan',
            reminderMinute: 18 * 60 + 5,
          ),
          categories: {'ent': 'Entertainment'},
        ),
        'Netflix,subscription,active,15.50,USD,monthly,1,2026-01-05,'
        '2026-10-20,no,,yes,3,18:05,Entertainment,Family plan,2026-02-03,Netflix',
      );
    });

    test('amounts use a point and two decimals', () {
      expect(row(item('A', amount: 1234.5)), contains(',1234.50,'));
      expect(row(item('B', amount: 0)), contains(',0.00,'));
      expect(row(item('C', amount: 3.999)), contains(',4.00,'));
    });

    test('names the frequency and the repeat count', () {
      String freq(BillingFrequency f, [int every = 1]) {
        final fields = row(item('X', frequency: f, interval: every)).split(',');
        return '${fields[5]}/${fields[6]}';
      }

      expect(freq(BillingFrequency.weekly), 'weekly/1');
      expect(freq(BillingFrequency.monthly, 2), 'monthly/2');
      expect(freq(BillingFrequency.quarterly), 'quarterly/1');
      expect(freq(BillingFrequency.semiAnnual), 'semi_annual/1');
      expect(freq(BillingFrequency.yearly), 'yearly/1');
      expect(freq(BillingFrequency.custom, 45), 'custom_days/45');
    });

    test('shows status, type and trial', () {
      final trial = row(
        item(
          'Trial',
          trialEnd: DateTime(2026, 11, 1),
          status: ItemStatus.paused,
        ),
      ).split(',');
      expect(trial[2], 'paused');
      expect(trial[9], 'yes');
      expect(trial[10], '2026-11-01');
      expect(
        row(item('Rent', type: RecurringItemType.bill)).split(',')[1],
        'bill',
      );
      expect(
        row(item('Old', status: ItemStatus.cancelled)).split(',')[2],
        'cancelled',
      );
    });

    test('shows reminders off and a zero-padded time', () {
      final fields = row(
        item('Quiet', reminders: false, reminderDays: 0, reminderMinute: 65),
      ).split(',');
      expect(fields[11], 'no');
      expect(fields[12], '0');
      expect(fields[13], '01:05');
    });

    test('an item without a category or notes leaves them empty', () {
      final fields = row(item('Plain')).split(',');
      expect(fields[14], '');
      expect(fields[15], '');
    });

    test('quotes commas, quotes and line breaks in names and notes', () {
      final csv = text(
        export(items: [item('Rent, flat "2"', notes: 'pay\non the 1st')])[0],
      );
      expect(csv, contains('"Rent, flat ""2"""'));
      expect(csv, contains('"pay\non the 1st"'));
    });

    test('defuses formulas in names, categories and notes', () {
      final csv = text(
        export(
          items: [
            item(
              '=HYPERLINK("http://x","y")',
              category: 'bad',
              notes: '@cmd|calc',
            ),
          ],
          categories: {'bad': '+SUM(1)'},
        )[0],
      );
      expect(csv, contains('"\'=HYPERLINK(""http://x"",""y"")"'));
      expect(csv, contains("'+SUM(1)"));
      expect(csv, contains("'@cmd|calc"));
    });

    test('keeps accents and other scripts intact', () {
      final csv = text(export(items: [item('Café 音楽 Zażółć')])[0]);
      expect(csv, contains('Café 音楽 Zażółć'));
    });

    test('keeps the order it was given', () {
      final csv = text(export(items: [item('Second'), item('First')])[0])
          .split('\r\n');
      expect(csv[1], startsWith('Second,'));
      expect(csv[2], startsWith('First,'));
    });
  });

  group('payments file', () {
    test('lists paid and skipped payments by subscription, oldest first', () {
      final csv = text(
        export(
          items: [item('Netflix'), item('Spotify', amount: 7)],
          payments: [
            payment(
              'p2',
              'Spotify',
              due: DateTime(2026, 9, 20),
              paid: DateTime(2026, 9, 21),
              amount: 7,
            ),
            payment(
              'p1',
              'Netflix',
              due: DateTime(2026, 8, 20),
              paid: DateTime(2026, 8, 20),
            ),
            payment(
              'p3',
              'Netflix',
              due: DateTime(2026, 10, 1),
              status: PaymentStatus.skipped,
            ),
          ],
        )[1],
      ).split('\r\n');

      expect(csv[1], 'Netflix,2026-08-20,2026-08-20,paid,10.00,USD,Netflix,p1');
      expect(csv[2], 'Spotify,2026-09-20,2026-09-21,paid,7.00,USD,Spotify,p2');
      expect(csv[3], 'Netflix,2026-10-01,,skipped,10.00,USD,Netflix,p3');
      expect(csv[4], '');
    });

    test('keeps the currency each payment was made in', () {
      final csv = text(
        export(
          items: [item('Rent', currency: 'EUR')],
          payments: [
            payment(
              'p1',
              'Rent',
              due: DateTime(2026, 9, 1),
              paid: DateTime(2026, 9, 1),
              currency: 'RWF',
              amount: 5000,
            ),
          ],
        )[1],
      );
      expect(csv, contains('Rent,2026-09-01,2026-09-01,paid,5000.00,RWF'));
    });

    test('skips payments whose subscription is missing', () {
      final csv = text(
        export(
          items: [item('Netflix')],
          payments: [payment('p1', 'ghost', due: DateTime(2026, 9, 1))],
        )[1],
      );
      expect(csv, isNot(contains('ghost')));
      expect(csv.split('\r\n').where((l) => l.isNotEmpty), hasLength(1));
    });

    test('defuses formulas in the subscription name', () {
      final csv = text(
        export(
          items: [item('=1+1', id: 'x')],
          payments: [
            payment(
              'p1',
              'x',
              due: DateTime(2026, 9, 1),
              paid: DateTime(2026, 9, 1),
            ),
          ],
        )[1],
      );
      expect(csv, contains("'=1+1,2026-09-01"));
    });

    test('with no payments is just the header', () {
      final csv = text(export(items: [item('Netflix')])[1]);
      expect(csv.split('\r\n').where((l) => l.isNotEmpty), hasLength(1));
    });
  });
}
