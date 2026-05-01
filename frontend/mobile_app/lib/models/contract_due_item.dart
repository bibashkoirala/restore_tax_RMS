import 'contract.dart';

class ContractDueItem {
  const ContractDueItem({
    required this.contract,
    required this.chargeLabel,
    required this.amountDue,
    required this.amountPaidOrQueued,
    required this.outstandingAmount,
  });

  final Contract contract;
  final String chargeLabel;
  final double amountDue;
  final double amountPaidOrQueued;
  final double outstandingAmount;

  bool get hasOutstanding => outstandingAmount > 0.009;
}
