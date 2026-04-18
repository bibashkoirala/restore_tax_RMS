import 'package:flutter/material.dart';

import '../models/transaction_entry.dart';
import '../services/mock_ledger_service.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_card.dart';

enum ReportPeriod { weekly, monthly, quarterly, yearly }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _service = MockLedgerService();

  ReportPeriod _selectedPeriod = ReportPeriod.monthly;

  Duration _windowFor(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.weekly:
        return const Duration(days: 7);
      case ReportPeriod.monthly:
        return const Duration(days: 30);
      case ReportPeriod.quarterly:
        return const Duration(days: 90);
      case ReportPeriod.yearly:
        return const Duration(days: 365);
    }
  }

  List<TransactionEntry> _transactionsForPeriod(List<TransactionEntry> source) {
    final now = DateTime.now();
    final window = _windowFor(_selectedPeriod);
    final start = now.subtract(window);
    return source.where((tx) => tx.occurredAt.isAfter(start)).toList();
  }

  double _sumByType(List<TransactionEntry> source, TransactionType type) =>
      source.where((tx) => tx.type == type).fold(0, (prev, tx) => prev + tx.amount);

  @override
  Widget build(BuildContext context) {
    final contract = _service.contract();
    final allTransactions = _service.transactions();
    final transactions = _transactionsForPeriod(allTransactions);
    final logs = _service.auditLogs();

    final rentTotal = _sumByType(transactions, TransactionType.rent);
    final utilityTotal =
        _sumByType(transactions, TransactionType.electricity) +
            _sumByType(transactions, TransactionType.water) +
            _sumByType(transactions, TransactionType.wasteManagement);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RTMS · Contract Ledger'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Contract ${contract.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-updated rent (today): NPR ${contract.rentForDate(DateTime.now()).toStringAsFixed(0)}',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: ReportPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return ChoiceChip(
                selected: isSelected,
                label: Text(period.name.toUpperCase()),
                selectedColor: AppTheme.govRed.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _selectedPeriod = period),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              SummaryCard(
                title: '${_selectedPeriod.name} Rent',
                amount: rentTotal,
                accent: AppTheme.govRed,
              ),
              SummaryCard(
                title: '${_selectedPeriod.name} Utilities',
                amount: utilityTotal,
                accent: Colors.black87,
              ),
              SummaryCard(
                title: 'Transactions',
                amount: transactions.length.toDouble(),
                accent: AppTheme.govRed,
              ),
              SummaryCard(
                title: 'Period Total',
                amount: rentTotal + utilityTotal,
                accent: Colors.black,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...transactions.map(
            (tx) => Card(
              child: ListTile(
                title: Text('${tx.type.name} · NPR ${tx.amount.toStringAsFixed(0)}'),
                subtitle: Text('${tx.status.name} · ${tx.reference}'),
                trailing: const Icon(Icons.receipt_long_rounded),
              ),
            ),
          ),
          if (transactions.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No transactions in selected period.'),
              ),
            ),
          const SizedBox(height: 16),
          Text('Audit Logs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...logs.map(
            (log) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(log.action),
              subtitle: Text('${log.actor} · ${log.createdAt.toIso8601String()}'),
              leading: const Icon(Icons.verified_user, color: AppTheme.govRed),
            ),
          ),
        ],
      ),
    );
  }
}
