import '../models/contract.dart';
import '../models/create_contract_request.dart';
import '../models/create_payment_request.dart';
import '../models/transaction_entry.dart';
import '../models/user_overview.dart';

abstract class LedgerService {
  Future<UserOverview> fetchOverview(String username);
  Future<TransactionEntry> claimTransaction({
    required String transactionId,
    required String username,
  });
  Future<TransactionEntry> approveTransaction({
    required String transactionId,
    required String username,
  });
  Future<Contract> approveContract({
    required String contractId,
    required String username,
  });
  Future<Contract> createContract({
    required String username,
    required CreateContractRequest request,
  });
  Future<TransactionEntry> createPayment({
    required String username,
    required CreatePaymentRequest request,
  });
}
