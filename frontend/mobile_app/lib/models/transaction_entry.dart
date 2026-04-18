enum TransactionType { rent, electricity, water, wasteManagement }
enum TransactionStatus { pending, completed, failed, disputed }

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.contractId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    required this.payerId,
    required this.payeeId,
    required this.status,
    required this.reference,
  });

  final String id;
  final String contractId;
  final TransactionType type;
  final double amount;
  final DateTime occurredAt;
  final String payerId;
  final String payeeId;
  final TransactionStatus status;
  final String reference;
}
