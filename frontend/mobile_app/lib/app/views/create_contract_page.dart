import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/create_contract_controller.dart';

class CreateContractPage extends GetView<CreateContractController> {
  const CreateContractPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Contract')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Share a contract with the client using their user id. The same notification channel will deliver the contract to them.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.clientIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Client user id',
                hintText: '2',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.municipalityIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Municipality user id',
                hintText: '3',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.annualIncrementController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Annual increment percent',
                hintText: '5',
              ),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Start date',
              value: _dateLabel(controller.startDate.value),
              onTap: () => controller.pickDate(context, isStartDate: true),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'End date',
              value: _dateLabel(controller.endDate.value),
              onTap: () => controller.pickDate(context, isStartDate: false),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recurring Charges',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.addCharge,
                  icon: const Icon(Icons.add),
                  label: const Text('Add charge'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...controller.charges.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: item.label,
                        decoration: const InputDecoration(
                          labelText: 'Charge label',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: item.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: 'NPR ',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => SwitchListTile(
                                value: item.isAutoIncrement.value,
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Auto increment'),
                                subtitle: const Text(
                                  'Apply annual increment to this charge.',
                                ),
                                onChanged: (value) {
                                  item.isAutoIncrement.value = value;
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: controller.charges.length > 1
                                ? () => controller.removeCharge(item)
                                : null,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional Terms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.termController,
                    decoration: const InputDecoration(
                      labelText: 'Optional term',
                      hintText: 'Internet bill paid by client',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: controller.addOptionalTerm,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.optionalTerms
                  .map(
                    (term) => InputChip(
                      label: Text(term),
                      onDeleted: () => controller.removeOptionalTerm(term),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: controller.isSubmitting.value ? null : controller.submit,
              icon: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                controller.isSubmitting.value
                    ? 'Sending contract...'
                    : 'Create and send contract',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value),
            const Icon(Icons.calendar_month_outlined),
          ],
        ),
      ),
    );
  }
}
