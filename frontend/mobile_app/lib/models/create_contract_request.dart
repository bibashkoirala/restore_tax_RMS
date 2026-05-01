import 'contract_charge.dart';

class CreateContractRequest {
  const CreateContractRequest({
    required this.clientId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.annualIncrementPercent,
    required this.recurringCharges,
    required this.optionalTerms,
    this.municipalityId,
  });

  final String clientId;
  final String? municipalityId;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double annualIncrementPercent;
  final List<ContractCharge> recurringCharges;
  final List<String> optionalTerms;

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      if (municipalityId != null && municipalityId!.isNotEmpty)
        'municipality_id': municipalityId,
      'start_date': _dateValue(startDate),
      'end_date': _dateValue(endDate),
      'base_rent': monthlyRent,
      'annual_increment_percent': annualIncrementPercent,
      'recurring_charges': recurringCharges.map((item) => item.toJson()).toList(),
      'optional_terms': optionalTerms,
    };
  }

  String _dateValue(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
