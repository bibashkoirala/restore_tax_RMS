import '../models/audit_log.dart';
import '../models/contract.dart';
import '../models/contract_charge.dart';
import '../models/create_contract_request.dart';
import '../models/create_payment_request.dart';
import '../models/notification_item.dart';
import '../models/party.dart';
import '../models/transaction_entry.dart';
import '../models/user_overview.dart';
import 'ledger_service.dart';

class MockLedgerService implements LedgerService {
  const MockLedgerService();

  static final Party _landlord = const Party(
    id: '1',
    name: 'Hari Landlord',
    username: 'hari_landlord',
    type: PartyType.landlord,
  );
  static final Party _client = const Party(
    id: '2',
    name: 'Sita Client',
    username: 'sita_client',
    type: PartyType.client,
  );
  static final Party _municipality = const Party(
    id: '3',
    name: 'Kathmandu Ward 5',
    username: 'ward5_admin',
    type: PartyType.municipality,
  );

  static bool _seeded = false;
  static final List<Contract> _contracts = [];
  static final List<TransactionEntry> _payments = [];
  static final Map<String, List<NotificationItem>> _notificationsByUser = {
    _landlord.username: [],
    _client.username: [],
    _municipality.username: [],
  };

  Party _partyForUsername(String username) {
    _ensureSeedData();
    switch (username) {
      case 'hari_landlord':
        return _landlord;
      case 'ward5_admin':
        return _municipality;
      default:
        return _client;
    }
  }

  void _ensureSeedData() {
    if (_seeded) {
      return;
    }
    _seeded = true;
    _contracts.add(
      Contract(
        backendId: '1',
        code: 'CTR-0001',
        landlord: _landlord,
        client: _client,
        municipality: _municipality,
        baseRent: 25000,
        startedAt: DateTime(2025, 1, 1),
        endsAt: DateTime(2028, 12, 31),
        incrementPercentPerYear: 5,
        status: ContractStatus.active,
        recurringCharges: const [
          ContractCharge(
            label: 'Monthly Rent',
            amount: 25000,
            isAutoIncrement: true,
          ),
          ContractCharge(
            label: 'Electricity',
            amount: 2200,
            isAutoIncrement: false,
          ),
          ContractCharge(
            label: 'Water',
            amount: 800,
            isAutoIncrement: false,
          ),
          ContractCharge(
            label: 'Waste',
            amount: 500,
            isAutoIncrement: false,
          ),
          ContractCharge(
            label: 'Internet',
            amount: 1500,
            isAutoIncrement: false,
          ),
        ],
        optionalTerms: const [
          'Client must keep payment references for every claim.',
        ],
        approvedAt: DateTime(2026, 4, 1, 9, 0),
      ),
    );
    _payments.addAll([
      TransactionEntry(
        id: '11',
        contractId: '1',
        type: TransactionType.water,
        amount: 800,
        occurredAt: DateTime(2026, 4, 2, 10, 0),
        payer: _client,
        payee: _landlord,
        status: TransactionStatus.approved,
        reference: 'PAY-APR-0001',
        chargeLabel: 'Water',
        canClaim: false,
        canApprove: false,
        auditLogs: [
          AuditLog(
            id: 'a1',
            actor: 'Hari Landlord',
            action: 'Payment Approved',
            createdAt: DateTime(2026, 4, 2, 10, 15),
            metadata: const {'transactionId': '11'},
          ),
        ],
        claimedBy: _client,
        claimedAt: DateTime(2026, 4, 2, 10, 0),
        approvedBy: _landlord,
        approvedAt: DateTime(2026, 4, 2, 10, 15),
      ),
      TransactionEntry(
        id: '12',
        contractId: '1',
        type: TransactionType.rent,
        amount: 5000,
        occurredAt: DateTime(2026, 4, 3, 11, 0),
        payer: _client,
        payee: _landlord,
        status: TransactionStatus.claimed,
        reference: 'PAY-APR-0002',
        chargeLabel: 'Monthly Rent',
        canClaim: false,
        canApprove: true,
        auditLogs: [
          AuditLog(
            id: 'a2',
            actor: 'Sita Client',
            action: 'Payment Submitted',
            createdAt: DateTime(2026, 4, 3, 11, 0),
            metadata: const {'transactionId': '12'},
          ),
        ],
        claimedBy: _client,
        claimedAt: DateTime(2026, 4, 3, 11, 0),
      ),
    ]);
    _notificationsByUser[_landlord.username] = [
      NotificationItem(
        id: 'n1',
        title: 'Payment Waiting Approval',
        message: 'Sita Client paid NPR 5000 for Monthly Rent in CTR-0001.',
        type: 'transaction_claimed',
        isRead: false,
        createdAt: DateTime(2026, 4, 3, 11, 0),
        contractCode: 'CTR-0001',
        transactionReference: 'PAY-APR-0002',
      ),
    ];
    _notificationsByUser[_client.username] = [
      NotificationItem(
        id: 'n2',
        title: 'Contract Active',
        message: 'Your contract CTR-0001 is active and ready for payment updates.',
        type: 'system',
        isRead: false,
        createdAt: DateTime(2026, 4, 1, 9, 0),
        contractCode: 'CTR-0001',
      ),
    ];
    _notificationsByUser[_municipality.username] = [
      NotificationItem(
        id: 'n3',
        title: 'Municipality Review',
        message: 'Ward office can review contract and payment ledger updates.',
        type: 'system',
        isRead: false,
        createdAt: DateTime(2026, 4, 1, 9, 0),
      ),
    ];
  }

  List<TransactionEntry> _transactions(Party viewer) {
    _ensureSeedData();
    return _payments.where((payment) {
      final contract = _contracts.firstWhere(
        (item) => item.backendId == payment.contractId,
      );
      if (viewer.isLandlord) {
        return contract.landlord.id == viewer.id;
      }
      if (viewer.isMunicipality) {
        return contract.municipality.id == viewer.id;
      }
      return contract.client.id == viewer.id;
    }).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  List<NotificationItem> _notifications(Party viewer) {
    _ensureSeedData();
    return List<NotificationItem>.from(
      _notificationsByUser[viewer.username] ?? const [],
    );
  }

  @override
  Future<UserOverview> fetchOverview(String username) async {
    final viewer = _partyForUsername(username);
    final contracts = _contracts.where((contract) {
      if (viewer.isLandlord) {
        return contract.landlord.id == viewer.id;
      }
      if (viewer.isMunicipality) {
        return contract.municipality.id == viewer.id;
      }
      return contract.client.id == viewer.id;
    }).toList();

    return UserOverview(
      user: viewer,
      contracts: contracts,
      transactions: _transactions(viewer),
      notifications: _notifications(viewer),
    );
  }

  @override
  Future<TransactionEntry> approveTransaction({
    required String transactionId,
    required String username,
  }) async {
    _ensureSeedData();
    final landlord = _partyForUsername(username);
    final index = _payments.indexWhere((payment) => payment.id == transactionId);
    final current = _payments[index];
    final approved = TransactionEntry(
      id: current.id,
      contractId: current.contractId,
      type: current.type,
      amount: current.amount,
      occurredAt: current.occurredAt,
      payer: current.payer,
      payee: current.payee,
      status: TransactionStatus.approved,
      reference: current.reference,
      chargeLabel: current.chargeLabel,
      canClaim: false,
      canApprove: false,
      auditLogs: current.auditLogs,
      claimedBy: current.claimedBy ?? current.payer,
      claimedAt: current.claimedAt ?? current.occurredAt,
      approvedBy: landlord,
      approvedAt: DateTime.now(),
    );
    _payments[index] = approved;
    final contract = _contracts.firstWhere((item) => item.backendId == current.contractId);
    _notificationsByUser[_client.username]!.insert(
      0,
      NotificationItem(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Approved',
        message:
            '${landlord.name} approved ${current.chargeLabel} payment for ${contract.code}.',
        type: 'transaction_approved',
        isRead: false,
        createdAt: DateTime.now(),
        contractCode: contract.code,
        transactionReference: current.reference,
      ),
    );
    _notificationsByUser[_municipality.username]!.insert(
      0,
      NotificationItem(
        id: 'n${DateTime.now().millisecondsSinceEpoch + 1}',
        title: 'Contract Ledger Updated',
        message:
            'Payment ${current.reference} for ${contract.code} was approved and the contract ledger was updated.',
        type: 'system',
        isRead: false,
        createdAt: DateTime.now(),
        contractCode: contract.code,
        transactionReference: current.reference,
      ),
    );
    return approved;
  }

  @override
  Future<Contract> approveContract({
    required String contractId,
    required String username,
  }) async {
    _ensureSeedData();
    final index = _contracts.indexWhere((contract) => contract.backendId == contractId);
    final current = _contracts[index];
    final updated = Contract(
      backendId: current.backendId,
      code: current.code,
      landlord: current.landlord,
      client: current.client,
      municipality: current.municipality,
      baseRent: current.baseRent,
      startedAt: current.startedAt,
      endsAt: current.endsAt,
      incrementPercentPerYear: current.incrementPercentPerYear,
      status: ContractStatus.active,
      recurringCharges: current.recurringCharges,
      optionalTerms: current.optionalTerms,
      approvedAt: DateTime.now(),
    );
    _contracts[index] = updated;
    return updated;
  }

  @override
  Future<TransactionEntry> claimTransaction({
    required String transactionId,
    required String username,
  }) async {
    return _transactions(_partyForUsername(username)).first;
  }

  @override
  Future<Contract> createContract({
    required String username,
    required CreateContractRequest request,
  }) async {
    _ensureSeedData();
    final landlord = _partyForUsername(username);
    if (request.clientId != _client.id) {
      throw Exception('Mock mode currently supports client user id 2 only.');
    }
    if (request.municipalityId != null &&
        request.municipalityId!.isNotEmpty &&
        request.municipalityId != _municipality.id) {
      throw Exception(
        'Mock mode currently supports municipality user id 3 only.',
      );
    }
    final nextId = (_contracts.length + 1).toString();
    final contract = Contract(
      backendId: nextId,
      code: 'CTR-${nextId.padLeft(4, '0')}',
      landlord: landlord,
      client: _client,
      municipality: _municipality,
      baseRent: request.monthlyRent,
      startedAt: request.startDate,
      endsAt: request.endDate,
      incrementPercentPerYear: request.annualIncrementPercent,
      status: ContractStatus.pendingApproval,
      recurringCharges: request.recurringCharges,
      optionalTerms: request.optionalTerms,
    );
    _contracts.add(contract);
    _notificationsByUser[_client.username]!.insert(
      0,
      NotificationItem(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Contract Shared',
        message:
            '${landlord.name} shared contract ${contract.code} with your user id ${_client.id}.',
        type: 'system',
        isRead: false,
        createdAt: DateTime.now(),
        contractCode: contract.code,
      ),
    );
    return contract;
  }

  @override
  Future<TransactionEntry> createPayment({
    required String username,
    required CreatePaymentRequest request,
  }) async {
    _ensureSeedData();
    final client = _partyForUsername(username);
    final contract = _contracts.firstWhere(
      (item) => item.backendId == request.contractId,
    );
    final id = (_payments.length + 11).toString();
    final payment = TransactionEntry(
      id: id,
      contractId: contract.backendId,
      type: _typeForChargeLabel(request.chargeLabel),
      amount: request.amount,
      occurredAt: DateTime.now(),
      payer: client,
      payee: contract.landlord,
      status: TransactionStatus.claimed,
      reference: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      chargeLabel: request.chargeLabel,
      canClaim: false,
      canApprove: true,
      auditLogs: [
        AuditLog(
          id: 'audit-$id',
          actor: client.name,
          action: 'Payment Submitted',
          createdAt: DateTime.now(),
          metadata: {
            'contractId': contract.backendId,
            'chargeLabel': request.chargeLabel,
          },
        ),
      ],
      claimedBy: client,
      claimedAt: DateTime.now(),
    );
    _payments.insert(0, payment);
    _notificationsByUser[_landlord.username]!.insert(
      0,
      NotificationItem(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Waiting Approval',
        message:
            '${client.name} paid NPR ${request.amount.toStringAsFixed(0)} for ${request.chargeLabel} in ${contract.code}.',
        type: 'transaction_claimed',
        isRead: false,
        createdAt: DateTime.now(),
        contractCode: contract.code,
        transactionReference: payment.reference,
      ),
    );
    return payment;
  }

  TransactionType _typeForChargeLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('rent')) {
      return TransactionType.rent;
    }
    if (normalized.contains('electric')) {
      return TransactionType.electricity;
    }
    if (normalized.contains('water')) {
      return TransactionType.water;
    }
    if (normalized.contains('waste')) {
      return TransactionType.wasteManagement;
    }
    if (normalized.contains('internet')) {
      return TransactionType.internet;
    }
    return TransactionType.other;
  }
}
