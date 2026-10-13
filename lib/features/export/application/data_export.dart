import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../payments/domain/payment.dart';
import '../../subscriptions/domain/recurring_enums.dart';
import '../../subscriptions/domain/recurring_item.dart';
import 'csv.dart';

/// One file to hand to the share sheet.
class ExportFile {
  const ExportFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

/// Passes files to the phone's share sheet. A seam, so tests do not need the
/// plugin.
abstract class DataSharer {
  Future<void> shareFiles(List<ExportFile> files, {required String title});
}

/// Overridden in `main.dart` with the share_plus implementation.
final dataSharerProvider = Provider<DataSharer>(
  (ref) => throw UnimplementedError('dataSharerProvider is not set up'),
);

const subscriptionsCsvHeader = [
  'name',
  'type',
  'status',
  'amount',
  'currency',
  'frequency',
  'every',
  'start_date',
  'next_due_date',
  'free_trial',
  'trial_end_date',
  'reminders',
  'reminder_days_before',
  'reminder_time',
  'category',
  'notes',
  'added_on',
  'id',
];

const paymentsCsvHeader = [
  'subscription',
  'due_date',
  'paid_date',
  'status',
  'amount',
  'currency',
  'subscription_id',
  'id',
];

/// UTF-8 byte order mark, so Excel reads accents and non-Latin names right.
const _byteOrderMark = [0xEF, 0xBB, 0xBF];

String _date(DateTime? date) {
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
}

String _time(int minuteOfDay) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(minuteOfDay ~/ 60)}:${two(minuteOfDay % 60)}';
}

/// A plain number with a point and two decimals, whatever the phone's
/// language, so a spreadsheet reads it the same everywhere.
String _amount(double amount) => amount.toStringAsFixed(2);

String _frequency(BillingFrequency frequency) => switch (frequency) {
  BillingFrequency.weekly => 'weekly',
  BillingFrequency.monthly => 'monthly',
  BillingFrequency.quarterly => 'quarterly',
  BillingFrequency.semiAnnual => 'semi_annual',
  BillingFrequency.yearly => 'yearly',
  // "every" counts days for custom, and units of the frequency otherwise.
  BillingFrequency.custom => 'custom_days',
};

String _status(PaymentStatus status) => switch (status) {
  PaymentStatus.paid => 'paid',
  PaymentStatus.skipped => 'skipped',
  PaymentStatus.upcoming => 'upcoming',
};

List<int> _encode(String csv) => [..._byteOrderMark, ...utf8.encode(csv)];

/// Builds the two export files from raw rows. Pure, so it is easy to test.
///
/// - `trackly-subscriptions-<date>.csv`: every subscription, bill and trial
///   with its schedule, status, reminder and notes, soonest due first.
/// - `trackly-payments-<date>.csv`: every recorded payment and skip, oldest
///   first, named by subscription.
///
/// User-typed text is protected against spreadsheet formulas (see [csvText]).
List<ExportFile> buildExportFiles({
  required List<RecurringItem> items,
  required List<Payment> payments,
  required Map<String, String> categoryNames,
  required DateTime now,
}) {
  final stamp = _date(now);
  final namesById = {for (final item in items) item.id: item.name};

  final subscriptions = buildCsv(subscriptionsCsvHeader, [
    for (final item in items)
      [
        csvText(item.name),
        item.type.name,
        item.status.name,
        _amount(item.amount),
        item.currencyCode,
        _frequency(item.frequency),
        '${item.interval}',
        _date(item.startDate),
        _date(item.nextDueDate),
        item.isTrial ? 'yes' : 'no',
        _date(item.trialEndDate),
        item.remindersEnabled ? 'yes' : 'no',
        '${item.reminderDaysBefore}',
        _time(item.reminderMinuteOfDay),
        csvText(categoryNames[item.categoryId] ?? ''),
        csvText(item.notes ?? ''),
        _date(item.createdAt),
        item.id,
      ],
  ]);

  final ordered = [...payments]
    ..sort((a, b) {
      final byDue = a.dueDate.compareTo(b.dueDate);
      return byDue != 0 ? byDue : a.createdAt.compareTo(b.createdAt);
    });
  final paymentRows = buildCsv(paymentsCsvHeader, [
    for (final payment in ordered)
      if (namesById[payment.recurringItemId] != null)
        [
          csvText(namesById[payment.recurringItemId]!),
          _date(payment.dueDate),
          _date(payment.paidDate),
          _status(payment.status),
          _amount(payment.amount),
          payment.currencyCode,
          payment.recurringItemId,
          payment.id,
        ],
  ]);

  return [
    ExportFile(
      name: 'trackly-subscriptions-$stamp.csv',
      bytes: _encode(subscriptions),
    ),
    ExportFile(
      name: 'trackly-payments-$stamp.csv',
      bytes: _encode(paymentRows),
    ),
  ];
}

/// Reads everything the user entered and hands it to the share sheet.
class DataExporter {
  DataExporter(this._ref);

  final Ref _ref;

  /// Shares the export. Returns false, without sharing, when there is nothing
  /// to export yet.
  Future<bool> run({required DateTime now, required String title}) async {
    final db = _ref.read(appDatabaseProvider);
    final items = await db.recurringItemsDao.getAll();
    if (items.isEmpty) return false;

    final payments = await db.paymentsDao.getAll();
    final categories = await db.categoriesDao.getAll();

    final files = buildExportFiles(
      items: items,
      payments: payments,
      categoryNames: {for (final c in categories) c.id: c.name},
      now: now,
    );
    await _ref.read(dataSharerProvider).shareFiles(files, title: title);
    return true;
  }
}

final dataExporterProvider = Provider<DataExporter>(DataExporter.new);
