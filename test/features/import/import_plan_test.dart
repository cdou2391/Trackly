import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/import/application/import_plan.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 13, 15, 30);

const _header = 'name,amount,currency,frequency,next_due_date';
const _categories = {'entertainment': 'cat-ent', 'software': 'cat-soft'};

RecurringItem existing(
  String id,
  String name, {
  double amount = 15.49,
  String currency = 'USD',
  BillingFrequency frequency = BillingFrequency.monthly,
  DateTime? due,
}) {
  return RecurringItem(
    id: id,
    name: name,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    startDate: DateTime(2026, 1, 20),
    nextDueDate: due ?? DateTime(2026, 10, 20),
    createdAt: _now,
    updatedAt: _now,
  );
}

Payment existingPayment(
  String id,
  String itemId, {
  DateTime? due,
  double amount = 15.49,
}) {
  return Payment(
    id: id,
    recurringItemId: itemId,
    amount: amount,
    currencyCode: 'USD',
    dueDate: due ?? DateTime(2026, 9, 20),
    paidDate: due ?? DateTime(2026, 9, 20),
    status: PaymentStatus.paid,
    createdAt: _now,
  );
}

ImportPlan plan(
  List<String> files, {
  List<RecurringItem> items = const [],
  List<Payment> payments = const [],
}) {
  var counter = 0;
  return buildImportPlan(
    sources: [
      for (var i = 0; i < files.length; i++)
        ImportSource(name: 'file${i + 1}.csv', text: files[i]),
    ],
    existingItems: items,
    existingPayments: payments,
    categoryIdsByName: _categories,
    now: _now,
    newId: () => 'new-${++counter}',
  );
}

ImportPlan one(String rows, {String header = _header}) =>
    plan(['$header\n$rows']);

List<ImportIssueKind> kinds(List<ImportIssue> issues) => [
  for (final i in issues) i.kind,
];

void main() {
  group('a subscriptions file', () {
    test('imports the minimum columns and fills in the rest', () {
      final p = one('Netflix,15.49,usd,monthly,2026-11-02');
      final item = p.newItems.single;

      expect(item.id, 'new-1');
      expect(item.name, 'Netflix');
      expect(item.amount, 15.49);
      expect(item.currencyCode, 'USD', reason: 'upper-cased');
      expect(item.frequency, BillingFrequency.monthly);
      expect(item.nextDueDate, DateTime(2026, 11, 2));
      expect(item.startDate, DateTime(2026, 11, 2), reason: 'defaults to due');
      expect(item.type, RecurringItemType.subscription);
      expect(item.status, ItemStatus.active);
      expect(item.interval, 1);
      expect(item.isTrial, isFalse);
      expect(item.remindersEnabled, isTrue);
      expect(item.reminderDaysBefore, 3);
      expect(item.reminderMinuteOfDay, 9 * 60);
      expect(item.categoryId, isNull);
      expect(item.notes, isNull);
      expect(item.createdAt, DateTime(2026, 10, 13));
      expect(p.problems, isEmpty);
      expect(p.fileProblems, isEmpty);
    });

    test('reads every column the export writes', () {
      final p = plan([
        'name,type,status,amount,currency,frequency,every,start_date,'
            'next_due_date,free_trial,trial_end_date,reminders,'
            'reminder_days_before,reminder_time,category,notes,added_on,id\n'
            'Gym,bill,paused,30.00,RWF,custom_days,45,2026-01-05,2026-10-20,'
            'no,,no,7,18:05,Entertainment,Pay at desk,2026-02-03,gym-1',
      ]);
      final item = p.newItems.single;

      expect(item.id, 'gym-1');
      expect(item.type, RecurringItemType.bill);
      expect(item.status, ItemStatus.paused);
      expect(item.amount, 30);
      expect(item.currencyCode, 'RWF');
      expect(item.frequency, BillingFrequency.custom);
      expect(item.interval, 45);
      expect(item.startDate, DateTime(2026, 1, 5));
      expect(item.nextDueDate, DateTime(2026, 10, 20));
      expect(item.remindersEnabled, isFalse);
      expect(item.reminderDaysBefore, 7);
      expect(item.reminderMinuteOfDay, 18 * 60 + 5);
      expect(item.categoryId, 'cat-ent');
      expect(item.notes, 'Pay at desk');
      expect(item.createdAt, DateTime(2026, 2, 3));
    });

    test('accepts a free trial with its end date', () {
      final p = one(
        'Notion,10,USD,monthly,2026-11-01,yes,2026-11-01',
        header: '$_header,free_trial,trial_end_date',
      );
      expect(p.newItems.single.isTrial, isTrue);
      expect(p.newItems.single.trialEndDate, DateTime(2026, 11, 1));
    });

    test('a free trial without an end date is a problem', () {
      final p = one(
        'Notion,10,USD,monthly,2026-11-01,yes,',
        header: '$_header,free_trial,trial_end_date',
      );
      expect(p.newItems, isEmpty);
      expect(kinds(p.problems), [ImportIssueKind.trialNeedsEnd]);
    });

    test('frequency names are forgiving', () {
      const names = {
        'Weekly': BillingFrequency.weekly,
        'MONTHLY': BillingFrequency.monthly,
        'quarterly': BillingFrequency.quarterly,
        'semi_annual': BillingFrequency.semiAnnual,
        'semi-annual': BillingFrequency.semiAnnual,
        'Semiannual': BillingFrequency.semiAnnual,
        'yearly': BillingFrequency.yearly,
        'annual': BillingFrequency.yearly,
        'custom_days': BillingFrequency.custom,
        'custom': BillingFrequency.custom,
      };
      for (final entry in names.entries) {
        final p = one('X,1,USD,${entry.key},2026-11-02');
        expect(p.newItems.single.frequency, entry.value, reason: entry.key);
      }
    });

    test('yes and no are forgiving', () {
      for (final yes in ['yes', 'YES', 'true', '1', 'y']) {
        final p = one(
          'X,1,USD,monthly,2026-11-02,$yes',
          header: '$_header,reminders',
        );
        expect(p.newItems.single.remindersEnabled, isTrue, reason: yes);
      }
      for (final no in ['no', 'false', '0', 'N']) {
        final p = one(
          'X,1,USD,monthly,2026-11-02,$no',
          header: '$_header,reminders',
        );
        expect(p.newItems.single.remindersEnabled, isFalse, reason: no);
      }
    });

    test('keeps surrounding spaces out of values', () {
      final p = one('  Netflix  , 15.49 , usd ,monthly, 2026-11-02 ');
      expect(p.newItems.single.name, 'Netflix');
      expect(p.newItems.single.amount, 15.49);
    });

    test('keeps accents and other scripts', () {
      final p = one('Café 音楽,3.5,EUR,monthly,2026-11-02');
      expect(p.newItems.single.name, 'Café 音楽');
    });
  });

  group('the formula guard is undone', () {
    test('only an apostrophe the export added is removed', () {
      final p = plan([
        '$_header,category,notes\n'
            "'=1+1,1,USD,monthly,2026-11-02,'+Software,'@mention\n"
            "'tis,1,USD,monthly,2026-11-02,,it's fine\n"
            "''=x,1,USD,monthly,2026-11-02,,\n",
      ]);
      final names = [for (final i in p.newItems) i.name];
      expect(names, ['=1+1', "'tis", "'=x"]);
      expect(p.newItems.first.notes, '@mention');
      expect(p.newItems[1].notes, "it's fine");
    });

    test('a guarded category name still finds its category', () {
      // "Software" is never guarded, but a user category such as "-Misc"
      // would be; this checks the restored text is what is looked up.
      final p = plan([
        '$_header,category\nX,1,USD,monthly,2026-11-02,Software\n',
      ]);
      expect(p.newItems.single.categoryId, 'cat-soft');
    });
  });

  group('categories', () {
    test('match by name, ignoring case', () {
      final p = one(
        'X,1,USD,monthly,2026-11-02,ENTERTAINMENT',
        header: '$_header,category',
      );
      expect(p.newItems.single.categoryId, 'cat-ent');
      expect(p.warnings, isEmpty);
    });

    test('an unknown one is left empty and noted, the row still imports', () {
      final p = one(
        'X,1,USD,monthly,2026-11-02,Pets',
        header: '$_header,category',
      );
      expect(p.newItems.single.categoryId, isNull);
      expect(kinds(p.warnings), [ImportIssueKind.unknownCategory]);
      expect(p.warnings.single.value, 'Pets');
      expect(p.problems, isEmpty);
    });
  });

  group('amounts', () {
    test('a point is the decimal separator in a comma file', () {
      expect(
        one('X,1234.50,USD,monthly,2026-11-02').newItems.single.amount,
        1234.5,
      );
      expect(one('X,0,USD,monthly,2026-11-02').newItems.single.amount, 0);
      expect(one('X,15,USD,monthly,2026-11-02').newItems.single.amount, 15);
    });

    test('a decimal comma is only understood in a semicolon file', () {
      final semicolon = plan([
        'name;amount;currency;frequency;next_due_date\n'
            'X;15,49;USD;monthly;2026-11-02\n',
      ]);
      expect(semicolon.newItems.single.amount, 15.49);

      final quoted = one('X,"15,49",USD,monthly,2026-11-02');
      expect(quoted.newItems, isEmpty);
      expect(kinds(quoted.problems), [ImportIssueKind.badAmount]);
    });

    test('rejects anything that is not a plain number', () {
      for (final bad in [
        '-5',
        '+5',
        r'$15',
        '15.49.1',
        '1e3',
        '1,000.00',
        'abc',
        '15 USD',
        '1000000001',
        '0x10',
        'NaN',
        'Infinity',
      ]) {
        final p = one('X,"$bad",USD,monthly,2026-11-02');
        expect(p.newItems, isEmpty, reason: bad);
        expect(kinds(p.problems), [ImportIssueKind.badAmount], reason: bad);
      }
    });

    test('an empty amount is "required"', () {
      final p = one('X,,USD,monthly,2026-11-02');
      expect(kinds(p.problems), [ImportIssueKind.required]);
      expect(p.problems.single.column, 'amount');
    });
  });

  group('dates', () {
    test('only real year-month-day dates are accepted', () {
      for (final bad in [
        '2026-02-30',
        '2026-13-01',
        '2026-2-3',
        '02/11/2026',
        '2026/11/02',
        '11 Nov 2026',
        '2026-11-02T10:00',
        '1800-01-01',
        '2500-01-01',
        'tomorrow',
      ]) {
        final p = one('X,1,USD,monthly,"$bad"');
        expect(p.newItems, isEmpty, reason: bad);
        expect(kinds(p.problems), [ImportIssueKind.badDate], reason: bad);
        expect(p.problems.single.column, 'next_due_date');
      }
    });

    test('a leap day is accepted only in a leap year', () {
      expect(one('X,1,USD,monthly,2028-02-29').newItems, hasLength(1));
      expect(one('X,1,USD,monthly,2027-02-29').newItems, isEmpty);
    });
  });

  group('other values', () {
    test('a row with an unknown choice is skipped and says which', () {
      final p = one(
        'X,1,USD,monthly,2026-11-02,archived',
        header: '$_header,status',
      );
      expect(p.newItems, isEmpty);
      expect(p.problems.single.kind, ImportIssueKind.badChoice);
      expect(p.problems.single.column, 'status');
      expect(p.problems.single.value, 'archived');
    });

    test('a currency must be three letters', () {
      for (final bad in ['US', 'USDD', '12A', r'$', r'U$D']) {
        final p = one('X,1,"$bad",monthly,2026-11-02');
        expect(kinds(p.problems), [ImportIssueKind.badChoice], reason: bad);
      }
    });

    test('an unknown frequency is a problem', () {
      final p = one('X,1,USD,fortnightly,2026-11-02');
      expect(kinds(p.problems), [ImportIssueKind.badChoice]);
      expect(p.problems.single.column, 'frequency');
    });

    test('every must be a whole number from 1 to 3650', () {
      for (final bad in ['0', '-1', '1.5', 'x', '3651', '1000000']) {
        final p = one(
          'X,1,USD,monthly,2026-11-02,"$bad"',
          header: '$_header,every',
        );
        expect(kinds(p.problems), [ImportIssueKind.badNumber], reason: bad);
      }
      final ok = one(
        'X,1,USD,monthly,2026-11-02,3650',
        header: '$_header,every',
      );
      expect(ok.newItems.single.interval, 3650);
    });

    test('reminder days must be 0 to 30', () {
      expect(
        kinds(
          one(
            'X,1,USD,monthly,2026-11-02,31',
            header: '$_header,reminder_days_before',
          ).problems,
        ),
        [ImportIssueKind.badNumber],
      );
      expect(
        one(
          'X,1,USD,monthly,2026-11-02,0',
          header: '$_header,reminder_days_before',
        ).newItems.single.reminderDaysBefore,
        0,
      );
    });

    test('reminder time is hours and minutes', () {
      for (final bad in ['24:00', '9', '09:60', '9:5', 'noon', '9am']) {
        final p = one(
          'X,1,USD,monthly,2026-11-02,"$bad"',
          header: '$_header,reminder_time',
        );
        expect(kinds(p.problems), [ImportIssueKind.badTime], reason: bad);
      }
      final ok = one(
        'X,1,USD,monthly,2026-11-02,9:05',
        header: '$_header,reminder_time',
      );
      expect(ok.newItems.single.reminderMinuteOfDay, 9 * 60 + 5);
    });

    test('names and notes have a length limit', () {
      final longName = 'n' * 121;
      expect(kinds(one('$longName,1,USD,monthly,2026-11-02').problems), [
        ImportIssueKind.tooLong,
      ]);
      expect(
        one('${'n' * 120},1,USD,monthly,2026-11-02').newItems,
        hasLength(1),
      );

      final longNotes = 'x' * 2001;
      final p = one(
        'X,1,USD,monthly,2026-11-02,$longNotes',
        header: '$_header,notes',
      );
      expect(p.problems.single.column, 'notes');
    });

    test('a blank name is "required"', () {
      final p = one(' ,1,USD,monthly,2026-11-02');
      expect(kinds(p.problems), [ImportIssueKind.required]);
      expect(p.problems.single.column, 'name');
    });

    test('ids may only use letters, digits, dash and underscore', () {
      for (final bad in ['a b', 'a/b', 'é', 'a' * 65, 'a;b']) {
        final p = one(
          'X,1,USD,monthly,2026-11-02,"$bad"',
          header: '$_header,id',
        );
        expect(kinds(p.problems), [ImportIssueKind.badId], reason: bad);
      }
      final ok = one(
        'X,1,USD,monthly,2026-11-02,3f2c-AA_1',
        header: '$_header,id',
      );
      expect(ok.newItems.single.id, '3f2c-AA_1');
    });

    test('extra values beyond the columns make the row a problem', () {
      // An unquoted comma in a name shifts everything along.
      final p = one('Rent, flat 2,1,USD,monthly,2026-11-02');
      expect(p.newItems, isEmpty);
      expect(
        p.problems.map((i) => i.kind),
        contains(ImportIssueKind.tooManyFields),
      );
    });

    test('empty trailing cells beyond the columns are harmless', () {
      final p = one('X,1,USD,monthly,2026-11-02,,,');
      expect(p.newItems, hasLength(1));
    });

    test('a row with several problems is reported with all of them', () {
      final p = one('X,abc,US,fortnightly,2026-02-30');
      expect(p.newItems, isEmpty);
      expect(kinds(p.problems), [
        ImportIssueKind.badAmount,
        ImportIssueKind.badChoice,
        ImportIssueKind.badChoice,
        ImportIssueKind.badDate,
      ]);
      expect(p.problems.every((i) => i.line == 2), isTrue);
    });

    test('good rows still import beside bad ones, with line numbers', () {
      final p = one(
        'Good,1,USD,monthly,2026-11-02\n'
        'Bad,x,USD,monthly,2026-11-02\n'
        'Also good,2,USD,monthly,2026-11-03',
      );
      expect([for (final i in p.newItems) i.name], ['Good', 'Also good']);
      expect(p.problems.single.line, 3);
      expect(p.problems.single.file, 'file1.csv');
    });

    test('a problem shows a shortened value', () {
      final p = one('X,${'9' * 100},USD,monthly,2026-11-02');
      expect(p.problems.single.value!.length, lessThan(50));
    });
  });

  group('files', () {
    test('a file without the required columns lists each missing one', () {
      final p = plan(['name,amount\nNetflix,15']);
      expect(p.newItems, isEmpty);
      expect(kinds(p.fileProblems), [
        ImportIssueKind.missingColumn,
        ImportIssueKind.missingColumn,
        ImportIssueKind.missingColumn,
      ]);
      expect(p.fileProblems.map((i) => i.column), [
        'currency',
        'frequency',
        'next_due_date',
      ]);
    });

    test('a file that is neither kind is not a Trackly file', () {
      final p = plan(['colour,size\nred,big']);
      expect(kinds(p.fileProblems), [ImportIssueKind.notTracklyFile]);
      expect(p.hasAnythingToImport, isFalse);
    });

    test('an empty file is not a Trackly file', () {
      expect(kinds(plan(['']).fileProblems), [ImportIssueKind.notTracklyFile]);
    });

    test('a file with a broken quote is reported with its line', () {
      final p = plan(['name,amount\n"oops,1']);
      expect(p.fileProblems.single.kind, ImportIssueKind.unclosedQuote);
      expect(p.fileProblems.single.line, 2);
    });

    test('one bad file does not stop the good one', () {
      final p = plan([
        'colour,size\nred,big',
        '$_header\nNetflix,15.49,USD,monthly,2026-11-02',
      ]);
      expect(p.newItems, hasLength(1));
      expect(p.fileProblems.single.file, 'file1.csv');
    });

    test('a header-only file imports nothing and has no problems', () {
      final p = plan(['$_header\n']);
      expect(p.hasAnythingToImport, isFalse);
      expect(p.fileProblems, isEmpty);
      expect(p.problems, isEmpty);
    });
  });

  group('never doubling up what Trackly has', () {
    test('a row whose id exists is left out, not replaced', () {
      final p = plan(
        ['$_header,id\nNetflix CHANGED,99,EUR,yearly,2027-01-01,nf-1'],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newItems, isEmpty);
      expect(p.duplicateItems, 1);
      expect(p.problems, isEmpty);
    });

    test('a row without an id that looks the same is left out', () {
      final p = plan(
        ['$_header\n netflix ,15.49,usd,Monthly,2026-10-20'],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newItems, isEmpty);
      expect(p.duplicateItems, 1);
    });

    test('a row without an id that differs in any key part is imported', () {
      for (final row in [
        'Netflix,15.50,USD,monthly,2026-10-20',
        'Netflix,15.49,EUR,monthly,2026-10-20',
        'Netflix,15.49,USD,yearly,2026-10-20',
        'Netflix,15.49,USD,monthly,2026-10-21',
        'Netflix 2,15.49,USD,monthly,2026-10-20',
      ]) {
        final p = plan(
          ['$_header\n$row'],
          items: [existing('nf-1', 'Netflix')],
        );
        expect(p.newItems, hasLength(1), reason: row);
      }
    });

    test('the same file twice in a row changes nothing the second time', () {
      const file =
          '$_header,id\nNetflix,15.49,USD,monthly,2026-10-20,nf-1\n'
          'Gym,30,USD,monthly,2026-10-25,gym-1';
      final first = plan([file]);
      expect(first.newItems, hasLength(2));

      final second = plan([file], items: first.newItems);
      expect(second.newItems, isEmpty);
      expect(second.duplicateItems, 2);
    });

    test('the same file without ids twice changes nothing the second time', () {
      const file = '$_header\nNetflix,15.49,USD,monthly,2026-10-20';
      final first = plan([file]);
      final second = plan([file], items: first.newItems);
      expect(second.newItems, isEmpty);
      expect(second.duplicateItems, 1);
    });

    test('the same id twice in one file keeps the first and reports the second', () {
      final p = plan([
        '$_header,id\nA,1,USD,monthly,2026-11-01,x1\nB,2,USD,monthly,2026-11-02,x1',
      ]);
      expect([for (final i in p.newItems) i.name], ['A']);
      expect(p.problems.single.kind, ImportIssueKind.duplicateIdInFile);
      expect(p.problems.single.line, 3);
      expect(p.problems.single.otherLine, 2);
    });

    test('identical rows without ids in one file import once', () {
      final p = one('A,1,USD,monthly,2026-11-01\nA,1,USD,monthly,2026-11-01');
      expect(p.newItems, hasLength(1));
      expect(p.duplicateItems, 1);
    });

    test('two files giving the same id import it once', () {
      final f = '$_header,id\nA,1,USD,monthly,2026-11-01,x1';
      final p = plan([f, f]);
      expect(p.newItems, hasLength(1));
      expect(kinds(p.problems), [ImportIssueKind.duplicateIdInFile]);
    });
  });

  group('a payments file', () {
    const payHeader = 'subscription,due_date,paid_date,status,amount,currency';

    test('attaches payments by name to an item already in Trackly', () {
      final p = plan(
        ['$payHeader\nNetflix,2026-09-20,2026-09-21,paid,15.49,USD'],
        items: [existing('nf-1', 'Netflix')],
      );
      final pay = p.newPayments.single;
      expect(pay.recurringItemId, 'nf-1');
      expect(pay.dueDate, DateTime(2026, 9, 20));
      expect(pay.paidDate, DateTime(2026, 9, 21));
      expect(pay.status, PaymentStatus.paid);
      expect(pay.amount, 15.49);
      expect(pay.currencyCode, 'USD');
      expect(pay.id, 'new-1');
      expect(pay.createdAt, _now);
    });

    test('matches names ignoring case and spaces', () {
      final p = plan(
        ['$payHeader\n  NETFLIX ,2026-09-20,2026-09-20,paid,15.49,USD'],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newPayments, hasLength(1));
    });

    test('attaches payments by subscription_id when present', () {
      final p = plan(
        [
          '$payHeader,subscription_id,id\n'
              'Whatever,2026-09-20,2026-09-20,paid,15.49,USD,nf-1,pay-7',
        ],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newPayments.single.recurringItemId, 'nf-1');
      expect(p.newPayments.single.id, 'pay-7');
    });

    test('works with a subscription_id and no name column at all', () {
      final p = plan(
        [
          'subscription_id,due_date,status,amount,currency\n'
              'nf-1,2026-09-20,skipped,15.49,USD',
        ],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newPayments.single.status, PaymentStatus.skipped);
    });

    test('attaches payments to items imported in the same go', () {
      final p = plan([
        '$_header,id\nGym,30,USD,monthly,2026-10-25,gym-1',
        '$payHeader,subscription_id\n'
            'Gym,2026-09-25,2026-09-25,paid,30,USD,gym-1\n'
            'Gym,2026-08-25,2026-08-25,paid,30,USD,',
      ]);
      expect(p.newItems, hasLength(1));
      expect(p.newPayments, hasLength(2));
      expect(p.newPayments.every((x) => x.recurringItemId == 'gym-1'), isTrue);
    });

    test('works whichever order the files are given in', () {
      final p = plan([
        '$payHeader\nGym,2026-09-25,2026-09-25,paid,30,USD',
        '$_header\nGym,30,USD,monthly,2026-10-25',
      ]);
      expect(p.newItems, hasLength(1));
      expect(p.newPayments, hasLength(1));
      expect(p.newPayments.single.recurringItemId, p.newItems.single.id);
    });

    test('an unknown name is a problem that points to the other file', () {
      final p = plan(['$payHeader\nNope,2026-09-20,,paid,1,USD']);
      expect(p.newPayments, isEmpty);
      expect(p.problems.single.kind, ImportIssueKind.unknownSubscription);
      expect(p.problems.single.value, 'Nope');
    });

    test('an unknown subscription_id is a problem', () {
      final p = plan(
        ['subscription_id,due_date,status,amount\nzzz,2026-09-20,paid,1'],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.problems.single.kind, ImportIssueKind.unknownSubscription);
      expect(p.problems.single.column, 'subscription_id');
    });

    test('a name shared by two subscriptions is ambiguous, not guessed', () {
      final p = plan(
        ['$payHeader\nGym,2026-09-20,2026-09-20,paid,30,USD'],
        items: [
          existing('g1', 'Gym', amount: 30),
          existing('g2', 'Gym', amount: 45),
        ],
      );
      expect(p.newPayments, isEmpty);
      expect(p.problems.single.kind, ImportIssueKind.ambiguousSubscription);
    });

    test('the same ambiguous name is fine when the id says which', () {
      final p = plan(
        [
          '$payHeader,subscription_id\n'
              'Gym,2026-09-20,2026-09-20,paid,30,USD,g2',
        ],
        items: [
          existing('g1', 'Gym', amount: 30),
          existing('g2', 'Gym', amount: 45),
        ],
      );
      expect(p.newPayments.single.recurringItemId, 'g2');
    });

    test('a paid payment with no paid date uses the due date and says so', () {
      final p = plan(
        ['$payHeader\nNetflix,2026-09-20,,paid,15.49,USD'],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newPayments.single.paidDate, DateTime(2026, 9, 20));
      expect(kinds(p.warnings), [ImportIssueKind.noPaidDate]);
    });

    test('a skipped payment has no paid date even if one is written', () {
      final p = plan(
        ['$payHeader\nNetflix,2026-09-20,2026-09-21,skipped,15.49,USD'],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newPayments.single.paidDate, isNull);
      expect(p.newPayments.single.status, PaymentStatus.skipped);
    });

    test('a missing currency falls back to the subscription\'s', () {
      final p = plan(
        ['$payHeader\nNetflix,2026-09-20,2026-09-20,paid,15.49,'],
        items: [existing('nf-1', 'Netflix', currency: 'EUR')],
      );
      expect(p.newPayments.single.currencyCode, 'EUR');
    });

    test('payment values are validated like the others', () {
      final p = plan(
        [
          '$payHeader\n'
              'Netflix,2026-02-30,,paid,15.49,USD\n'
              'Netflix,2026-09-20,,refunded,15.49,USD\n'
              'Netflix,2026-09-20,,paid,-3,USD\n'
              'Netflix,2026-09-20,,paid,15.49,US\n'
              'Netflix,2026-09-20,2026-09-20,paid,15.49,USD',
        ],
        items: [existing('nf-1', 'Netflix')],
      );
      expect(p.newPayments, hasLength(1));
      expect(kinds(p.problems), [
        ImportIssueKind.badDate,
        ImportIssueKind.badChoice,
        ImportIssueKind.badAmount,
        ImportIssueKind.badChoice,
      ]);
    });

    test('a payment Trackly already has is left out', () {
      final p = plan(
        [
          '$payHeader,subscription_id,id\n'
              'Netflix,2026-09-20,2026-09-20,paid,15.49,USD,nf-1,pay-1',
        ],
        items: [existing('nf-1', 'Netflix')],
        payments: [existingPayment('pay-1', 'nf-1')],
      );
      expect(p.newPayments, isEmpty);
      expect(p.duplicatePayments, 1);
    });

    test('a payment without an id that looks the same is left out', () {
      final p = plan(
        ['$payHeader\nNetflix,2026-09-20,2026-09-20,paid,15.49,USD'],
        items: [existing('nf-1', 'Netflix')],
        payments: [existingPayment('pay-1', 'nf-1')],
      );
      expect(p.newPayments, isEmpty);
      expect(p.duplicatePayments, 1);
    });

    test('importing a full export twice adds nothing the second time', () {
      const subs = '$_header,id\nNetflix,15.49,USD,monthly,2026-10-20,nf-1';
      const pays =
          '$payHeader,subscription_id,id\n'
          'Netflix,2026-09-20,2026-09-20,paid,15.49,USD,nf-1,pay-1';
      final first = plan([subs, pays]);
      expect(first.newItems, hasLength(1));
      expect(first.newPayments, hasLength(1));

      final second = plan(
        [subs, pays],
        items: first.newItems,
        payments: first.newPayments,
      );
      expect(second.hasAnythingToImport, isFalse);
      expect(second.duplicates, 2);
    });

    test('a payments file missing a required column is a file problem', () {
      final p = plan(['subscription,due_date\nNetflix,2026-09-20']);
      expect(kinds(p.fileProblems), [
        ImportIssueKind.missingColumn,
        ImportIssueKind.missingColumn,
      ]);
      expect(p.fileProblems.map((i) => i.column), ['status', 'amount']);
    });
  });

  test('a plan reports whether there is anything to import', () {
    expect(one('X,1,USD,monthly,2026-11-02').hasAnythingToImport, isTrue);
    expect(one('X,abc,USD,monthly,2026-11-02').hasAnythingToImport, isFalse);
  });
}
