import 'package:drift/drift.dart';

import '../../../features/payments/domain/payment.dart';
import '../app_database.dart';
import '../tables/payments_table.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [Payments])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<void> insertPayment(Payment payment) {
    return into(payments).insert(payment.toCompanion());
  }

  /// Most recently paid payments (skipped ones are not "recent payments").
  Stream<List<Payment>> watchRecentPaid({int limit = 5}) {
    final query = select(payments)
      ..where((t) => t.status.equalsValue(PaymentStatus.paid))
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidDate),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit);
    return query.watch();
  }

  /// Full history for one item, newest due date first.
  Stream<List<Payment>> watchForItem(String recurringItemId) {
    final query = select(payments)
      ..where((t) => t.recurringItemId.equals(recurringItemId))
      ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]);
    return query.watch();
  }

  Future<int> clearHistory() => delete(payments).go();
}

extension PaymentToCompanion on Payment {
  PaymentsCompanion toCompanion() {
    return PaymentsCompanion(
      id: Value(id),
      recurringItemId: Value(recurringItemId),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      dueDate: Value(dueDate),
      paidDate: Value(paidDate),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }
}
