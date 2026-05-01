import 'audit_log.dart';
import 'party.dart';

enum TransactionType { rent, electricity, water, wasteManagement, internet, other }
enum TransactionStatus { pending, claimed, approved, failed, disputed }

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.contractId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    required this.payer,
    required this.payee,
    required this.status,
    required this.reference,
    required this.chargeLabel,
    required this.canClaim,
    required this.canApprove,
    required this.auditLogs,
    this.claimedBy,
    this.approvedBy,
    this.claimedAt,
    this.approvedAt,
  });

  final String id;
  final String contractId;
  final TransactionType type;
  final double amount;
  final DateTime occurredAt;
  final Party payer;
  final Party payee;
  final TransactionStatus status;
  final String reference;
  final String chargeLabel;
  final bool canClaim;
  final bool canApprove;
  final List<AuditLog> auditLogs;
  final Party? claimedBy;
  final Party? approvedBy;
  final DateTime? claimedAt;
  final DateTime? approvedAt;

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      id: json['id'].toString(),
      contractId: json['contract'].toString(),
      type: switch (json['transaction_type']) {
        'rent' => TransactionType.rent,
        'electricity' => TransactionType.electricity,
        'water' => TransactionType.water,
        'waste_management' => TransactionType.wasteManagement,
        'internet' => TransactionType.internet,
        'other' => TransactionType.other,
        _ => TransactionType.rent,
      },
      amount: double.parse(json['amount'].toString()),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      payer: Party.fromJson(json['payer'] as Map<String, dynamic>),
      payee: Party.fromJson(json['payee'] as Map<String, dynamic>),
      status: switch (json['status']) {
        'pending' => TransactionStatus.pending,
        'claimed' => TransactionStatus.claimed,
        'approved' => TransactionStatus.approved,
        'failed' => TransactionStatus.failed,
        'disputed' => TransactionStatus.disputed,
        _ => TransactionStatus.pending,
      },
      reference: json['payment_reference'] as String,
      chargeLabel: json['charge_label'] as String? ?? json['transaction_type'] as String? ?? 'Charge',
      canClaim: json['can_claim'] as bool? ?? false,
      canApprove: json['can_approve'] as bool? ?? false,
      auditLogs: (json['audit_logs'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(AuditLog.fromJson)
          .toList(),
      claimedBy: json['claimed_by'] == null
          ? null
          : Party.fromJson(json['claimed_by'] as Map<String, dynamic>),
      approvedBy: json['approved_by'] == null
          ? null
          : Party.fromJson(json['approved_by'] as Map<String, dynamic>),
      claimedAt: json['claimed_at'] == null
          ? null
          : DateTime.parse(json['claimed_at'] as String),
      approvedAt: json['approved_at'] == null
          ? null
          : DateTime.parse(json['approved_at'] as String),
    );
  }
}
