class CreatePaymentRequest {
  const CreatePaymentRequest({
    required this.contractId,
    required this.chargeLabel,
    required this.amount,
  });

  final String contractId;
  final String chargeLabel;
  final double amount;

  Map<String, dynamic> toJson() {
    return {
      'contract_id': contractId,
      'charge_label': chargeLabel,
      'amount': amount,
    };
  }
}
