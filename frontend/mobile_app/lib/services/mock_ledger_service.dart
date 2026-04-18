import '../models/audit_log.dart';
import '../models/contract.dart';
import '../models/party.dart';
import '../models/transaction_entry.dart';

class MockLedgerService {
  const MockLedgerService();

  List<Party> parties() => const [
        Party(id: 'P-1', name: 'Hari Landlord', type: PartyType.landlord),
        Party(id: 'P-2', name: 'Sita Client', type: PartyType.client),
        Party(
          id: 'P-3',
          name: 'Kathmandu Municipality Ward-05',
          type: PartyType.municipality,
        ),
      ];

  Contract contract() => Contract(
        id: 'C-1001',
        baseRent: 25000,
        startedAt: DateTime(2025, 1, 1),
        endsAt: DateTime(2028, 12, 31),
        incrementPercentPerYear: 5,
      );

  List<TransactionEntry> transactions() => [
        TransactionEntry(
          id: 'T-1',
          contractId: 'C-1001',
          type: TransactionType.rent,
          amount: 25000,
          occurredAt: DateTime(2026, 4, 3),
          payerId: 'P-2',
          payeeId: 'P-1',
          status: TransactionStatus.completed,
          reference: 'FONEPAY-APR-001',
        ),
        TransactionEntry(
          id: 'T-2',
          contractId: 'C-1001',
          type: TransactionType.electricity,
          amount: 2300,
          occurredAt: DateTime(2026, 4, 5),
          payerId: 'P-2',
          payeeId: 'P-1',
          status: TransactionStatus.completed,
          reference: 'WALLET-APR-EL-003',
        ),
        TransactionEntry(
          id: 'T-3',
          contractId: 'C-1001',
          type: TransactionType.water,
          amount: 700,
          occurredAt: DateTime(2026, 4, 7),
          payerId: 'P-2',
          payeeId: 'P-1',
          status: TransactionStatus.pending,
          reference: 'INV-WAT-APR-08',
        ),
      ];

  List<AuditLog> auditLogs() => [
        AuditLog(
          id: 'A-1',
          actor: 'Sita Client',
          action: 'Transaction Initiated',
          createdAt: DateTime(2026, 4, 7, 10, 32),
          metadata: const {'transactionId': 'T-3', 'channel': 'wallet'},
        ),
        AuditLog(
          id: 'A-2',
          actor: 'Hari Landlord',
          action: 'Rent Payment Verified',
          createdAt: DateTime(2026, 4, 3, 11, 15),
          metadata: const {'transactionId': 'T-1', 'proof': 'receipt-uploaded'},
        ),
        AuditLog(
          id: 'A-3',
          actor: 'Ward Officer',
          action: 'Monthly Compliance Reviewed',
          createdAt: DateTime(2026, 4, 10, 15, 40),
          metadata: const {'period': '2026-04'},
        ),
      ];
}
