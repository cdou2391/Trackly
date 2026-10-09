/// Trackly does not process payments, so there is no "failed" status.
enum PaymentStatus { upcoming, paid, skipped }

class Payment {
  const Payment({
    required this.id,
    required this.recurringItemId,
    required this.amount,
    required this.currencyCode,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String recurringItemId;

  final double amount;
  final String currencyCode;

  final DateTime dueDate;
  final DateTime? paidDate;

  final PaymentStatus status;
  final DateTime createdAt;
}
