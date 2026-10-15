import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import 'package:trackly/features/subscriptions/application/items_filter.dart';

import '../../helpers/test_app.dart';

const _size = Size(390, 1400);

/// Netflix, due 15 Oct (today in tests is 9 Oct), opened on its detail screen.
Future<AppDatabase> _openNetflix(WidgetTester tester) async {
  final db = await pumpTrackly(
    tester,
    size: _size,
    items: [
      testItem(
        'Netflix',
        amount: 15.49,
        due: DateTime(2026, 10, 15),
        logoKey: 'netflix',
      ),
    ],
  );
  await tester.tap(find.text('Netflix'));
  await settle(tester);
  return db;
}

Future<List<Payment>> _payments(WidgetTester tester, AppDatabase db) async {
  return (await tester.runAsync(
    () => db.paymentsDao.watchForItem('Netflix').first,
  ))!;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await settle(tester);
}

void main() {
  group('detail screen', () {
    tracklyTest('opens from an Upcoming row and shows the item', (
      tester,
    ) async {
      await _openNetflix(tester);

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text(r'$15.49  Monthly', findRichText: true), findsOneWidget);
      expect(find.text('Next charge'), findsOneWidget);
      expect(find.text('Oct 15, 2026'), findsOneWidget);
      expect(find.text('Reminder 1'), findsOneWidget);
      expect(find.text('3 days before at 9:00 AM'), findsOneWidget);
      expect(find.text('Reminder 2'), findsOneWidget);
      expect(find.text('On the day at 9:00 AM'), findsOneWidget);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Mark as paid'), findsOneWidget);
      expect(find.text('Skip this charge'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Payment history'), findsOneWidget);
      expect(find.text('No payments recorded yet.'), findsOneWidget);
      expect(find.text('Cancel subscription'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    tracklyTest('shows the item\'s own reminder time', (tester) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [
          testItem(
            'Netflix',
            due: DateTime(2026, 10, 15),
            reminderMinuteOfDay: 18 * 60 + 30,
          ),
        ],
      );
      await tester.tap(find.text('Netflix'));
      await settle(tester);

      // The early reminder keeps the chosen time, the day itself is at 9:00.
      expect(find.text('3 days before at 6:30 PM'), findsOneWidget);
      expect(find.text('On the day at 9:00 AM'), findsOneWidget);
    });

    tracklyTest('same day is one reminder, off is none', (tester) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [
          testItem(
            'Netflix',
            due: DateTime(2026, 10, 15),
            reminderDaysBefore: 0,
            reminderMinuteOfDay: 18 * 60 + 30,
          ),
          testItem(
            'Spotify',
            due: DateTime(2026, 10, 16),
            remindersEnabled: false,
          ),
        ],
      );
      await tester.tap(find.text('Netflix'));
      await settle(tester);
      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('Same day at 6:30 PM'), findsOneWidget);
      expect(find.text('Reminder 1'), findsNothing);
      expect(find.text('On the day at 9:00 AM'), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      await tester.tap(find.text('Spotify'));
      await settle(tester);
      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Reminder 1'), findsNothing);
    });

    tracklyTest('back returns to Home', (tester) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.text('Your recurring cost'), findsOneWidget);
    });

    tracklyTest('is reachable from the status cards, See all and history', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [testItem('Netflix', due: DateTime(2026, 10, 15))],
      );
      await tester.tap(find.text('Active'));
      await settle(tester);
      expect(find.text('All subscriptions'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
    });
  });

  group('mark as paid', () {
    tracklyTest('records the payment and moves the next charge a month on', (
      tester,
    ) async {
      final db = await _openNetflix(tester);

      await _tapText(tester, 'Mark as paid');

      expect(find.text('Marked as paid — next charge Nov 15'), findsOneWidget);
      // The due chip and the schedule row both show the date.
      expect(find.text('Nov 15, 2026'), findsNWidgets(2));
      final payment = (await _payments(tester, db)).single;
      expect(payment.status, PaymentStatus.paid);
      expect(payment.dueDate, DateTime(2026, 10, 15));
      expect(payment.paidDate, DateTime(2026, 10, 9));
      // The history shows it.
      expect(find.text('Due Oct 15, 2026'), findsOneWidget);
      expect(find.text('Paid Oct 9'), findsOneWidget);
      expect(find.text('No payments recorded yet.'), findsNothing);
    });

    tracklyTest('Undo takes it back', (tester) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Mark as paid');
      await _tapText(tester, 'Undo');

      expect(await _payments(tester, db), isEmpty);
      expect(find.text('Oct 15, 2026'), findsOneWidget);
      expect(find.text('No payments recorded yet.'), findsOneWidget);
    });
  });

  group('skip', () {
    tracklyTest('records a skipped charge and moves on', (tester) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Skip this charge');

      expect(find.text('Skipped — next charge Nov 15'), findsOneWidget);
      final payment = (await _payments(tester, db)).single;
      expect(payment.status, PaymentStatus.skipped);
      expect(find.text('Skipped'), findsOneWidget);
      // The due chip and the schedule row both show the date.
      expect(find.text('Nov 15, 2026'), findsNWidgets(2));
    });
  });

  group('pause and resume', () {
    tracklyTest('pausing swaps the actions for Resume and leaves Upcoming', (
      tester,
    ) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Pause');

      expect(find.text('Paused'), findsWidgets);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Mark as paid'), findsNothing);
      expect(find.text('Skip this charge'), findsNothing);
      final stored = (await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      ))!;
      expect(stored.status, ItemStatus.paused);

      // Back on Home it is no longer upcoming.
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.text('No upcoming charges'), findsOneWidget);
    });

    tracklyTest('resuming asks for the next charge date', (tester) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Pause');
      await _tapText(tester, 'Resume');

      // The date picker opens on the next real occurrence; accept it.
      expect(find.text('Next charge date'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(find.text('Resume'), findsNothing);
      expect(find.text('Mark as paid'), findsOneWidget);
      final stored = (await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      ))!;
      expect(stored.status, ItemStatus.active);
      expect(stored.nextDueDate, DateTime(2026, 10, 15));
    });

    tracklyTest('cancelling the date picker leaves it paused', (tester) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Pause');
      await _tapText(tester, 'Resume');
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      final stored = (await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      ))!;
      expect(stored.status, ItemStatus.paused);
    });
  });

  group('cancel subscription', () {
    tracklyTest('asks first, then keeps the item and its history', (
      tester,
    ) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Mark as paid');
      await _tapText(tester, 'Cancel subscription');

      expect(find.text('Cancel Netflix?'), findsOneWidget);
      expect(
        find.text(
          'Reminders and due dates stop. Your payment history is kept.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.widgetWithText(TextButton, 'Cancel subscription').last,
      );
      await settle(tester);

      final stored = (await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      ))!;
      expect(stored.status, ItemStatus.cancelled);
      expect(await _payments(tester, db), hasLength(1));
      // The actions are gone; history stays.
      expect(find.text('Mark as paid'), findsNothing);
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.text('Paid Oct 9'), findsOneWidget);
      expect(find.text('Next charge'), findsNothing);
    });

    tracklyTest('Keep it does nothing', (tester) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Cancel subscription');
      await tester.tap(find.text('Keep it'));
      await settle(tester);

      final stored = (await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      ))!;
      expect(stored.status, ItemStatus.active);
    });
  });

  group('cancel and delete buttons', () {
    Rect rect(WidgetTester tester, String label) => tester.getRect(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );

    tracklyTest('sit side by side, level with each other', (tester) async {
      await _openNetflix(tester);

      final cancel = rect(tester, 'Cancel subscription');
      final delete = rect(tester, 'Delete');

      expect(cancel.top, delete.top);
      expect(cancel.height, delete.height);
      expect(cancel.right, lessThan(delete.left));
      // Both stay comfortable to hit.
      expect(cancel.height, greaterThanOrEqualTo(48));
      expect(delete.width, greaterThanOrEqualTo(48));
    });

    tracklyTest('stack when large text would squeeze the labels', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: const Size(390, 1800),
        textScale: 1.4,
        items: [testItem('Netflix', due: DateTime(2026, 10, 15))],
      );
      await tester.tap(find.text('Netflix'));
      await settle(tester);

      final cancel = rect(tester, 'Cancel subscription');
      final delete = rect(tester, 'Delete');

      expect(delete.top, greaterThan(cancel.bottom));
      expect(cancel.left, delete.left);
      expect(cancel.width, delete.width);
      expect(tester.takeException(), isNull);
    });

    tracklyTest('a cancelled item only offers Delete, full width', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [testItem('Netflix', status: ItemStatus.cancelled)],
      );
      await tester.tap(find.text('More').last);
      await settle(tester);
      await tester.tap(find.text('All subscriptions'));
      await settle(tester);
      await tester.tap(find.text('Netflix'));
      await settle(tester);

      expect(find.text('Cancel subscription'), findsNothing);
      final delete = rect(tester, 'Delete');
      expect(delete.width, greaterThan(300));
    });

    tracklyTest('fit a narrow screen without overflow', (tester) async {
      await pumpTrackly(
        tester,
        size: const Size(320, 1400),
        items: [testItem('Netflix', due: DateTime(2026, 10, 15))],
      );
      await tester.tap(find.text('Netflix'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Cancel subscription'), findsOneWidget);
    });
  });

  group('delete', () {
    tracklyTest('asks first, then removes the item and returns to Home', (
      tester,
    ) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Mark as paid');
      await _tapText(tester, 'Delete');

      expect(find.text('Delete Netflix?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
      await settle(tester);

      expect(
        await tester.runAsync(() => db.recurringItemsDao.getById('Netflix')),
        isNull,
      );
      expect(await _payments(tester, db), isEmpty);
      // Back on Home, with a confirmation.
      expect(find.text('Your recurring cost'), findsOneWidget);
      expect(find.text('Deleted'), findsOneWidget);
      expect(find.text('No upcoming charges'), findsOneWidget);
    });

    tracklyTest('Not now keeps it', (tester) async {
      final db = await _openNetflix(tester);
      await _tapText(tester, 'Delete');
      await tester.tap(find.text('Not now'));
      await settle(tester);

      expect(
        await tester.runAsync(() => db.recurringItemsDao.getById('Netflix')),
        isNotNull,
      );
      expect(find.text('Payment history'), findsOneWidget);
    });
  });

  group('edit', () {
    final panel = find.byKey(const Key('add-panel'));
    Finder inPanel(Finder f) => find.descendant(of: panel, matching: f);

    tracklyTest('opens the panel filled in, from this screen', (tester) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      // Exactly one panel: this screen's, not the one under Home.
      expect(panel, findsOneWidget);
      expect(inPanel(find.text('Edit subscription')), findsOneWidget);
      final name = tester.widget<TextField>(
        inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
      );
      expect(name.controller!.text, 'Netflix');
      final amount = tester.widget<TextField>(
        inPanel(find.widgetWithText(TextField, 'Amount')),
      );
      expect(amount.controller!.text, '15.49');
      expect(inPanel(find.text('Next charge')), findsOneWidget);
      expect(inPanel(find.text('Save changes')), findsOneWidget);
    });

    tracklyTest('saving changes updates the item and the screen', (
      tester,
    ) async {
      final db = await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      await tester.enterText(
        inPanel(find.widgetWithText(TextField, 'Amount')),
        '22.99',
      );
      await tester.pump();
      await tester.tap(
        inPanel(find.widgetWithText(FilledButton, 'Save changes')),
      );
      await settle(tester);

      expect(panel, findsNothing);
      expect(find.text('Changes saved'), findsOneWidget);
      expect(find.text(r'$22.99  Monthly', findRichText: true), findsOneWidget);
      final stored = (await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      ))!;
      expect(stored.amount, 22.99);
      // Everything else is untouched, including the logo and schedule.
      expect(stored.name, 'Netflix');
      expect(stored.logoKey, 'netflix');
      expect(stored.nextDueDate, DateTime(2026, 10, 15));
      expect(stored.status, ItemStatus.active);
    });

    tracklyTest('editing shows the reminder time and saves a new one', (
      tester,
    ) async {
      final db = await pumpTrackly(
        tester,
        size: _size,
        items: [
          testItem(
            'Netflix',
            due: DateTime(2026, 10, 15),
            reminderMinuteOfDay: 18 * 60 + 30,
          ),
        ],
      );
      await tester.tap(find.text('Netflix'));
      await settle(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      expect(inPanel(find.text('Remind me at')), findsOneWidget);
      expect(inPanel(find.text('6:30 PM')), findsOneWidget);

      await tester.ensureVisible(inPanel(find.text('6:30 PM')));
      await tester.pump();
      await tester.tap(inPanel(find.text('6:30 PM')));
      await settle(tester);
      await tester.tap(find.byTooltip('Switch to text input mode'));
      await settle(tester);
      final fields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '7');
      await tester.enterText(fields.at(1), '15');
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('AM')),
      );
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester);

      await tester.tap(
        inPanel(find.widgetWithText(FilledButton, 'Save changes')),
      );
      await settle(tester);

      expect(find.text('3 days before at 7:15 AM'), findsOneWidget);
      final stored = (await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      ))!;
      expect(stored.reminderMinuteOfDay, 7 * 60 + 15);
      // Everything else is untouched.
      expect(stored.reminderDaysBefore, 3);
      expect(stored.nextDueDate, DateTime(2026, 10, 15));
    });

    tracklyTest('Save is disabled when the name is cleared', (tester) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      await tester.enterText(
        inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
        '',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              inPanel(find.widgetWithText(FilledButton, 'Save changes')),
            )
            .onPressed,
        isNull,
      );
    });

    tracklyTest('add still opens the add panel on Home afterwards', (
      tester,
    ) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      await tester.tap(find.byTooltip('Close'));
      await settle(tester);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);

      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await settle(tester);
      expect(inPanel(find.text('Add subscription')), findsOneWidget);
      final name = tester.widget<TextField>(
        inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
      );
      expect(name.controller!.text, isEmpty);
    });
  });

  group('lists', () {
    tracklyTest('More links to All subscriptions and Payment history', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [testItem('Netflix', due: DateTime(2026, 10, 15))],
      );
      await tester.tap(find.text('More'));
      await settle(tester);

      await tester.tap(find.text('All subscriptions'));
      await settle(tester);
      expect(find.text('Netflix'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);

      await tester.tap(find.text('Payment history'));
      await settle(tester);
      expect(
        find.text('Payments you mark as paid will show up here.'),
        findsOneWidget,
      );
    });

    tracklyTest('filters narrow the list', (tester) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [
          testItem('Netflix', due: DateTime(2026, 10, 15)),
          testItem(
            'Canva',
            due: DateTime(2026, 11, 5),
            trialEnd: DateTime(2026, 11, 5),
          ),
        ],
      );
      await tester.tap(find.text('More'));
      await settle(tester);
      await tester.tap(find.text('All subscriptions'));
      await settle(tester);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Canva'), findsOneWidget);

      await tester.tap(find.widgetWithText(Tab, 'Trial'));
      await settle(tester);
      expect(find.text('Netflix'), findsNothing);
      expect(find.text('Canva'), findsOneWidget);

      await tester.tap(find.widgetWithText(Tab, 'Cancelled'));
      await settle(tester);
      expect(find.text('Nothing here yet.'), findsOneWidget);
    });

    tracklyTest('a status card opens the list already filtered', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [
          testItem('Netflix', due: DateTime(2026, 10, 15)),
          testItem(
            'Canva',
            due: DateTime(2026, 11, 5),
            trialEnd: DateTime(2026, 11, 5),
          ),
        ],
      );
      await tester.tap(find.text('Trial').first);
      await settle(tester);

      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
        ItemFilter.trial.index,
      );
      expect(find.text('Canva'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
    });

    tracklyTest('history lists payments and opens the item', (tester) async {
      final db = await pumpTrackly(
        tester,
        size: _size,
        items: [testItem('Netflix', due: DateTime(2026, 10, 15))],
      );
      await tester.runAsync(
        () => db.paymentsDao.insertPayment(
          Payment(
            id: 'p1',
            recurringItemId: 'Netflix',
            amount: 10,
            currencyCode: 'USD',
            dueDate: DateTime(2026, 9, 15),
            paidDate: DateTime(2026, 9, 16),
            status: PaymentStatus.paid,
            createdAt: testNow,
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('See all').last);
      await settle(tester);

      expect(find.text('Payment history'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Due Sep 15, 2026'), findsOneWidget);
      expect(find.text('Paid Sep 16'), findsOneWidget);

      await tester.tap(find.text('Netflix'));
      await settle(tester);
      expect(find.text('Mark as paid'), findsOneWidget);
    });
  });
}
