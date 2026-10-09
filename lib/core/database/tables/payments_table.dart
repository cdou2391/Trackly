// Column constraints refer to their own column inside check(); that is
// Drift's documented pattern, so the lint does not apply here.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../../features/payments/domain/payment.dart';
import '../converters.dart';
import 'recurring_items_table.dart';

@UseRowClass(Payment)
@TableIndex(name: 'idx_payments_item', columns: {#recurringItemId})
@TableIndex(name: 'idx_payments_paid_date', columns: {#paidDate})
class Payments extends Table {
  TextColumn get id => text()();

  /// Deleting an item deletes its payment history.
  TextColumn get recurringItemId =>
      text().references(RecurringItems, #id, onDelete: KeyAction.cascade)();

  RealColumn get amount => real().check(amount.isBiggerOrEqualValue(0))();
  TextColumn get currencyCode => text()();

  TextColumn get dueDate => text().map(const DateOnlyConverter())();
  TextColumn get paidDate => text().map(const DateOnlyConverter()).nullable()();

  TextColumn get status => textEnum<PaymentStatus>()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
