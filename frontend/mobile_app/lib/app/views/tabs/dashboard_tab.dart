import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/contract.dart';
import '../../../models/contract_due_item.dart';
import '../../../models/create_payment_request.dart';
import '../../../models/party.dart';
import '../../../models/transaction_entry.dart';
import '../../controllers/overview_controller.dart';
import '../widgets/home_section_card.dart';

class DashboardTab extends GetView<OverviewController> {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user;
      if (user == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome ${user.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _roleMessage(user),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (controller.errorMessage.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          if (user.isLandlord)
            _buildLandlordHome(context)
          else if (user.isClient)
            _buildClientHome(context)
          else
            _buildMunicipalityHome(context),
        ],
      );
    });
  }

  Widget _buildMunicipalityHome(BuildContext context) {
    return Column(
      children: [
        _metricGrid([
          _MetricData(
            title: 'Actual Contracts',
            value: controller.actualContractCount.toString(),
            accent: Colors.black,
          ),
          _MetricData(
            title: 'Contract Total',
            value: 'NPR ${controller.activeContractTotalAmount.toStringAsFixed(0)}',
            accent: Colors.red.shade700,
          ),
          _MetricData(
            title: 'Pending',
            value: controller.pendingContractCount.toString(),
            accent: Colors.orange.shade700,
          ),
          _MetricData(
            title: 'Pending Amount',
            value: 'NPR ${controller.pendingApprovalAmount.toStringAsFixed(0)}',
            accent: Colors.black87,
          ),
        ]),
        const SizedBox(height: 16),
        HomeSectionCard(
          title: 'Monthly Transactions',
          subtitle:
              'All client transaction totals grouped by month across the municipality.',
          child: _monthlyGraph(context),
        ),
        const SizedBox(height: 16),
        HomeSectionCard(
          title: 'Municipality updates',
          subtitle:
              'Latest contract and ledger updates after landlord verification.',
          trailing: const Chip(label: Text('Read only')),
          child: _notificationList(
            context,
            emptyText: 'No municipality updates are available yet.',
          ),
        ),
      ],
    );
  }

  Widget _buildClientHome(BuildContext context) {
    return Column(
      children: [
        _metricGrid([
          _MetricData(
            title: 'Exact Due',
            value: 'NPR ${controller.totalOutstandingDue.toStringAsFixed(0)}',
            accent: Colors.red.shade700,
          ),
          _MetricData(
            title: 'Next Payment',
            value: _dateText(controller.nextPaymentDate),
            accent: Colors.black,
          ),
          _MetricData(
            title: 'Days Left',
            value: controller.daysLeftToNextPayment.toString(),
            accent: Colors.orange.shade700,
          ),
        ]),
        const SizedBox(height: 16),
        HomeSectionCard(
          title: 'Days Left Graph',
          subtitle:
              'Progress toward the next payment date for your active contract cycle.',
          child: _daysLeftGraph(context),
        ),
        const SizedBox(height: 16),
        HomeSectionCard(
          title: 'Current due amount',
          subtitle:
              'Pay all dues, only rent, only utilities, or any partial amount.',
          trailing: Chip(
            label: Text('NPR ${controller.totalOutstandingDue.toStringAsFixed(0)}'),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: controller.outstandingDueItems.isEmpty
                      ? null
                      : controller.payAllOutstandingDues,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Pay all dues'),
                ),
              ),
              const SizedBox(height: 12),
              _dueList(context, controller.outstandingDueItems),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HomeSectionCard(
          title: 'Approval progress',
          subtitle:
              'Submitted payments waiting for landlord confirmation.',
          child: _transactionList(
            context,
            controller.claimedTransactions,
            emptyText: 'No claimed transactions are waiting for approval.',
          ),
        ),
      ],
    );
  }

  Widget _buildLandlordHome(BuildContext context) {
    return Column(
      children: [
        _metricGrid([
          _MetricData(
            title: 'Contract Count',
            value: controller.actualContractCount.toString(),
            accent: Colors.black,
          ),
          _MetricData(
            title: 'To Be Received',
            value: 'NPR ${controller.totalOutstandingDue.toStringAsFixed(0)}',
            accent: Colors.red.shade700,
          ),
          _MetricData(
            title: 'Pending Claims',
            value: controller.claimedTransactions.length.toString(),
            accent: Colors.orange.shade700,
          ),
        ]),
        const SizedBox(height: 16),
        HomeSectionCard(
          title: 'Tenant Client Cards',
          subtitle:
              'Each tenant shows days left on contract and amount left to receive.',
          child: _tenantCards(context),
        ),
        const SizedBox(height: 16),
        HomeSectionCard(
          title: 'Pending landlord actions',
          subtitle:
              'Approve submitted payments and keep the contract ledger current.',
          trailing: Chip(
            label: Text(
              '${controller.pendingContracts.length + controller.claimedTransactions.length} open',
            ),
          ),
          child: Column(
            children: [
              if (controller.pendingContracts.isEmpty &&
                  controller.claimedTransactions.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('No approval work is waiting right now.'),
                ),
              ...controller.pendingContracts.map(_contractActionTile),
              ...controller.claimedTransactions.map(
                (tx) => _transactionActionTile(
                  context,
                  tx,
                  titlePrefix: tx.chargeLabel,
                  actionLabel: 'Approve claim',
                  onPressed: () => controller.approveTransaction(tx.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricGrid(List<_MetricData> items) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) => _MetricCard(data: items[index]),
    );
  }

  Widget _monthlyGraph(BuildContext context) {
    final points = controller.monthlyTransactionSeries;
    final maxTotal = points.fold<double>(0.0, (max, item) => item.total > max ? item.total : max);
    return Column(
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 36, child: Text(point.label)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: maxTotal == 0 ? 0 : point.total / maxTotal,
                        minHeight: 14,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: Text(
                      'NPR ${point.total.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _daysLeftGraph(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: controller.nextPaymentProgress.clamp(0.0, 1.0),
            minHeight: 18,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          controller.nextPaymentDate == null
              ? 'No active payment schedule available.'
              : '${controller.daysLeftToNextPayment} days left until ${_dateText(controller.nextPaymentDate)}',
        ),
      ],
    );
  }

  Widget _tenantCards(BuildContext context) {
    if (controller.landlordClientSnapshots.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('No tenant contracts are active right now.'),
      );
    }

    return Column(
      children: controller.landlordClientSnapshots
          .map(
            (snapshot) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.contract.client.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('Contract: ${snapshot.contract.code}'),
                    Text('Days left: ${snapshot.daysLeft}'),
                    Text('Amount left to get: NPR ${snapshot.amountLeft.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _contractActionTile(Contract contract) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(contract.code),
      subtitle: Text(
        'Client ${contract.client.name} | Rent NPR ${contract.rentForDate(DateTime.now()).toStringAsFixed(0)}',
      ),
      trailing: FilledButton(
        onPressed: () => controller.approveContract(contract.backendId),
        child: const Text('Approve'),
      ),
    );
  }

  Widget _transactionActionTile(
    BuildContext context,
    TransactionEntry tx, {
    String? titlePrefix,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${titlePrefix ?? tx.chargeLabel} - NPR ${tx.amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Reference: ${tx.reference}'),
            Text('Status: ${tx.status.name}'),
            Text('Payer: ${tx.payer.name}'),
            const SizedBox(height: 8),
            if (actionLabel != null && onPressed != null)
              FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }

  Widget _dueList(BuildContext context, List<ContractDueItem> items) {
    if (items.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('No dues are outstanding right now.'),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.chargeLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('Contract: ${item.contract.code}'),
                    Text('Exact due: NPR ${item.outstandingAmount.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => controller.createPayment(
                            CreatePaymentRequest(
                              contractId: item.contract.backendId,
                              chargeLabel: item.chargeLabel,
                              amount: item.outstandingAmount,
                            ),
                          ),
                          child: const Text('Pay full'),
                        ),
                        OutlinedButton(
                          onPressed: () => _showPartialPaymentDialog(context, item),
                          child: const Text('Pay partial'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _showPartialPaymentDialog(
    BuildContext context,
    ContractDueItem item,
  ) async {
    final amountController = TextEditingController();
    await Get.dialog(
      AlertDialog(
        title: Text('Partial payment for ${item.chargeLabel}'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: item.outstandingAmount.toStringAsFixed(0),
            prefixText: 'NPR ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0 || amount > item.outstandingAmount) {
                Get.snackbar(
                  'Invalid amount',
                  'Enter an amount up to the outstanding due.',
                );
                return;
              }
              Get.back();
              controller.createPayment(
                CreatePaymentRequest(
                  contractId: item.contract.backendId,
                  chargeLabel: item.chargeLabel,
                  amount: amount,
                ),
              );
            },
            child: const Text('Submit payment'),
          ),
        ],
      ),
    );
    amountController.dispose();
  }

  Widget _notificationList(BuildContext context, {required String emptyText}) {
    if (controller.notifications.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(emptyText),
      );
    }

    return Column(
      children: controller.notifications
          .map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(item.message),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _transactionList(
    BuildContext context,
    List<TransactionEntry> transactions, {
    required String emptyText,
  }) {
    if (transactions.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(emptyText),
      );
    }

    return Column(
      children: transactions
          .map((tx) => _transactionActionTile(context, tx))
          .toList(),
    );
  }

  String _dateText(DateTime? value) {
    if (value == null) {
      return '--';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _roleMessage(Party user) {
    if (user.isMunicipality) {
      return 'Municipality sees actual contracts, live totals, pending items, and monthly client transaction movement.';
    }
    if (user.isLandlord) {
      return 'Landlord sees contracts, expected receivables, and tenant-wise remaining time and balance.';
    }
    return 'Client sees exact due, next payment date, and time left before the next payment cycle.';
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data.title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Text(
              data.value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: data.accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
