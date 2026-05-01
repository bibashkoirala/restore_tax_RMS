import 'party.dart';
import 'contract_charge.dart';

enum ContractStatus { pendingApproval, active, expired }

class Contract {
  const Contract({
    required this.backendId,
    required this.code,
    required this.landlord,
    required this.client,
    required this.municipality,
    required this.baseRent,
    required this.startedAt,
    required this.endsAt,
    required this.incrementPercentPerYear,
    required this.status,
    required this.recurringCharges,
    required this.optionalTerms,
    this.approvedAt,
  });

  final String backendId;
  final String code;
  final Party landlord;
  final Party client;
  final Party municipality;
  final double baseRent;
  final DateTime startedAt;
  final DateTime endsAt;
  final double incrementPercentPerYear;
  final ContractStatus status;
  final List<ContractCharge> recurringCharges;
  final List<String> optionalTerms;
  final DateTime? approvedAt;

  bool get isPendingApproval => status == ContractStatus.pendingApproval;
  bool get isActive => status == ContractStatus.active;

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      backendId: json['id'].toString(),
      code: json['code'] as String,
      landlord: Party.fromJson(json['landlord'] as Map<String, dynamic>),
      client: Party.fromJson(json['client'] as Map<String, dynamic>),
      municipality: Party.fromJson(json['municipality'] as Map<String, dynamic>),
      baseRent: double.parse(json['base_rent'].toString()),
      startedAt: DateTime.parse(json['start_date'] as String),
      endsAt: DateTime.parse(json['end_date'] as String),
      incrementPercentPerYear: double.parse(
        json['annual_increment_percent'].toString(),
      ),
      status: switch (json['status']) {
        'pending_approval' => ContractStatus.pendingApproval,
        'active' => ContractStatus.active,
        'expired' => ContractStatus.expired,
        _ => ContractStatus.pendingApproval,
      },
      recurringCharges: (json['recurring_charges'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ContractCharge.fromJson)
          .toList(),
      optionalTerms: (json['optional_terms'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      approvedAt: json['approved_at'] == null
          ? null
          : DateTime.parse(json['approved_at'] as String),
    );
  }

  double rentForDate(DateTime date) {
    final yearDiff = date.year - startedAt.year;
    final factor = 1 + ((incrementPercentPerYear / 100) * yearDiff);
    return baseRent * factor;
  }

  double chargeAmountForDate(ContractCharge charge, DateTime date) {
    if (!charge.isAutoIncrement) {
      return charge.amount;
    }
    final yearDiff = date.year - startedAt.year;
    final factor = 1 + ((incrementPercentPerYear / 100) * yearDiff);
    return charge.amount * factor;
  }

  double totalChargeAmountForDate(DateTime date) {
    return recurringCharges.fold(
      0.0,
      (sum, charge) => sum + chargeAmountForDate(charge, date),
    );
  }
}
