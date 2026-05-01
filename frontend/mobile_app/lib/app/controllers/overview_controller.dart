import 'package:get/get.dart';

import '../../models/contract.dart';
import '../../models/contract_due_item.dart';
import '../../models/create_contract_request.dart';
import '../../models/create_payment_request.dart';
import '../../models/notification_item.dart';
import '../../models/party.dart';
import '../../models/transaction_entry.dart';
import '../../models/user_overview.dart';
import '../../services/ledger_service.dart';
import '../routes/app_pages.dart';
import 'session_controller.dart';

class MonthlyTransactionPoint {
  const MonthlyTransactionPoint({
    required this.label,
    required this.total,
  });

  final String label;
  final double total;
}

class ContractClientSnapshot {
  const ContractClientSnapshot({
    required this.contract,
    required this.daysLeft,
    required this.amountLeft,
  });

  final Contract contract;
  final int daysLeft;
  final double amountLeft;
}

class OverviewController extends GetxController {
  OverviewController(this._service, this._sessionController);

  final LedgerService _service;
  final SessionController _sessionController;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedTab = 0.obs;
  final overview = Rxn<UserOverview>();

  Party? get user => overview.value?.user;
  List<Contract> get contracts => overview.value?.contracts ?? const [];
  List<TransactionEntry> get transactions => overview.value?.transactions ?? const [];
  List<NotificationItem> get notifications =>
      overview.value?.notifications ?? const [];
  List<TransactionEntry> get recentTransactions => transactions.take(3).toList();
  List<TransactionEntry> get pendingTransactions => transactions
      .where((tx) => tx.status == TransactionStatus.pending)
      .toList();
  List<TransactionEntry> get claimedTransactions => transactions
      .where((tx) => tx.status == TransactionStatus.claimed)
      .toList();
  List<TransactionEntry> get actionableTransactions => transactions
      .where((tx) => tx.canClaim || tx.canApprove)
      .toList();
  List<Contract> get pendingContracts => contracts
      .where((contract) => contract.isPendingApproval)
      .toList();
  int get unreadNotificationCount => notifications.where((item) => !item.isRead).length;
  List<Contract> get activeContracts =>
      contracts.where((contract) => contract.isActive).toList();
  int get actualContractCount => activeContracts.length;
  int get pendingContractCount => pendingContracts.length;
  double get activeContractTotalAmount => activeContracts.fold(
        0.0,
        (sum, contract) => sum + contract.totalChargeAmountForDate(DateTime.now()),
      );
  double get pendingApprovalAmount => claimedTransactions.fold(
        0.0,
        (sum, tx) => sum + tx.amount,
      );
  List<ContractDueItem> get dueItems {
    final items = <ContractDueItem>[];
    for (final contract in contracts) {
      for (final charge in contract.recurringCharges) {
        final alreadyPaid = transactions
            .where(
              (tx) =>
                  tx.contractId == contract.backendId &&
                  tx.chargeLabel.toLowerCase() == charge.label.toLowerCase() &&
                  tx.status != TransactionStatus.failed &&
                  tx.status != TransactionStatus.disputed,
            )
            .fold(0.0, (sum, tx) => sum + tx.amount);
        final amountDue = contract.chargeAmountForDate(charge, DateTime.now());
        final outstanding = (amountDue - alreadyPaid).clamp(0, double.infinity);
        items.add(
          ContractDueItem(
            contract: contract,
            chargeLabel: charge.label,
            amountDue: amountDue,
            amountPaidOrQueued: alreadyPaid,
            outstandingAmount: outstanding.toDouble(),
          ),
        );
      }
    }
    return items;
  }
  List<ContractDueItem> get outstandingDueItems =>
      dueItems.where((item) => item.hasOutstanding).toList();
  double get totalOutstandingDue => outstandingDueItems.fold(
        0.0,
        (sum, item) => sum + item.outstandingAmount,
      );
  DateTime? get nextPaymentDate {
    if (activeContracts.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    DateTime? earliest;
    for (final contract in activeContracts) {
      final anchorDay = contract.startedAt.day;
      var candidate = DateTime(now.year, now.month, anchorDay);
      if (!candidate.isAfter(now)) {
        candidate = DateTime(now.year, now.month + 1, anchorDay);
      }
      if (earliest == null || candidate.isBefore(earliest)) {
        earliest = candidate;
      }
    }
    return earliest;
  }
  int get daysLeftToNextPayment {
    final nextDate = nextPaymentDate;
    if (nextDate == null) {
      return 0;
    }
    return nextDate.difference(DateTime.now()).inDays.clamp(0, 9999);
  }
  double get nextPaymentProgress {
    final nextDate = nextPaymentDate;
    if (nextDate == null) {
      return 0;
    }
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month, 1);
    final totalDays = nextDate.difference(anchor).inDays;
    if (totalDays <= 0) {
      return 0;
    }
    final elapsed = now.difference(anchor).inDays.clamp(0, totalDays);
    return elapsed / totalDays;
  }
  List<MonthlyTransactionPoint> get monthlyTransactionSeries {
    final now = DateTime.now();
    final points = <MonthlyTransactionPoint>[];
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final label = _monthLabel(date);
      final total = transactions
          .where(
            (tx) => tx.occurredAt.year == date.year && tx.occurredAt.month == date.month,
          )
          .fold(0.0, (sum, tx) => sum + tx.amount);
      points.add(MonthlyTransactionPoint(label: label, total: total));
    }
    return points;
  }
  List<ContractClientSnapshot> get landlordClientSnapshots {
    return activeContracts.map((contract) {
      final amountLeft = outstandingDueItems
          .where((item) => item.contract.backendId == contract.backendId)
          .fold(0.0, (sum, item) => sum + item.outstandingAmount);
      final daysLeft = contract.endsAt.difference(DateTime.now()).inDays.clamp(0, 99999);
      return ContractClientSnapshot(
        contract: contract,
        daysLeft: daysLeft,
        amountLeft: amountLeft,
      );
    }).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
  }

  double get totalApprovedAmount => transactions
      .where((tx) => tx.status == TransactionStatus.approved)
      .fold(0, (sum, tx) => sum + tx.amount);

  Future<void> login(String username) async {
    await _load(username);
    if (overview.value != null) {
      _sessionController.signIn(overview.value!.user);
      Get.offAllNamed(AppPages.home);
    }
  }

  Future<void> refreshOverview() async {
    final username = _sessionController.username;
    if (username.isEmpty) {
      return;
    }
    await _load(username, redirectOnError: false);
  }

  Future<void> claimTransaction(String transactionId) async {
    final username = _sessionController.username;
    if (username.isEmpty) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _service.claimTransaction(
        transactionId: transactionId,
        username: username,
      );
      await refreshOverview();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createPayment(CreatePaymentRequest request) async {
    final username = _sessionController.username;
    if (username.isEmpty) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _service.createPayment(username: username, request: request);
      await refreshOverview();
    } catch (error) {
      errorMessage.value = error.toString();
      Get.snackbar('Payment failed', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> payAllOutstandingDues() async {
    for (final item in outstandingDueItems) {
      await createPayment(
        CreatePaymentRequest(
          contractId: item.contract.backendId,
          chargeLabel: item.chargeLabel,
          amount: item.outstandingAmount,
        ),
      );
    }
  }

  Future<void> approveTransaction(String transactionId) async {
    final username = _sessionController.username;
    if (username.isEmpty) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _service.approveTransaction(
        transactionId: transactionId,
        username: username,
      );
      await refreshOverview();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveContract(String contractId) async {
    final username = _sessionController.username;
    if (username.isEmpty) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _service.approveContract(
        contractId: contractId,
        username: username,
      );
      await refreshOverview();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createContract(CreateContractRequest request) async {
    final username = _sessionController.username;
    if (username.isEmpty) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _service.createContract(username: username, request: request);
      await refreshOverview();
      selectedTab.value = 1;
    } catch (error) {
      errorMessage.value = error.toString();
      Get.snackbar('Create contract failed', errorMessage.value);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  void logout() {
    overview.value = null;
    errorMessage.value = '';
    _sessionController.signOut();
    Get.offAllNamed(AppPages.login);
  }

  Future<void> _load(String username, {bool redirectOnError = true}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      overview.value = await _service.fetchOverview(username);
    } catch (error) {
      errorMessage.value = error.toString();
      overview.value = null;
      if (redirectOnError) {
        Get.snackbar('Login failed', errorMessage.value);
      }
    } finally {
      isLoading.value = false;
    }
  }

  String _monthLabel(DateTime date) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[date.month - 1];
  }
}
