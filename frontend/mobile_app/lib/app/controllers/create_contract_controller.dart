import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/contract_charge.dart';
import '../../models/create_contract_request.dart';
import 'overview_controller.dart';

class ChargeFieldController {
  ChargeFieldController({
    required this.label,
    String amount = '',
    bool isAutoIncrement = false,
  })  : amountController = TextEditingController(text: amount),
        isAutoIncrement = isAutoIncrement.obs;

  final TextEditingController label;
  final TextEditingController amountController;
  final RxBool isAutoIncrement;

  void dispose() {
    label.dispose();
    amountController.dispose();
  }
}

class CreateContractController extends GetxController {
  CreateContractController(this._overviewController);

  final OverviewController _overviewController;

  final clientIdController = TextEditingController(text: '2');
  final municipalityIdController = TextEditingController(text: '3');
  final annualIncrementController = TextEditingController(text: '5');
  final termController = TextEditingController();

  final startDate = DateTime.now().obs;
  final endDate = DateTime.now().add(const Duration(days: 365)).obs;
  final charges = <ChargeFieldController>[].obs;
  final optionalTerms = <String>[].obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    charges.addAll([
      ChargeFieldController(
        label: TextEditingController(text: 'Monthly Rent'),
        amount: '25000',
        isAutoIncrement: true,
      ),
      ChargeFieldController(
        label: TextEditingController(text: 'Electricity'),
        amount: '2200',
      ),
      ChargeFieldController(
        label: TextEditingController(text: 'Water'),
        amount: '800',
      ),
      ChargeFieldController(
        label: TextEditingController(text: 'Waste'),
        amount: '500',
      ),
    ]);
  }

  Future<void> pickDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate.value : endDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }
    if (isStartDate) {
      startDate.value = selected;
      if (!endDate.value.isAfter(selected)) {
        endDate.value = selected.add(const Duration(days: 365));
      }
    } else {
      endDate.value = selected;
    }
  }

  void addCharge() {
    charges.add(
      ChargeFieldController(label: TextEditingController(text: 'Internet')),
    );
  }

  void removeCharge(ChargeFieldController charge) {
    charges.remove(charge);
    charge.dispose();
  }

  void addOptionalTerm() {
    final term = termController.text.trim();
    if (term.isEmpty) {
      return;
    }
    optionalTerms.add(term);
    termController.clear();
  }

  void removeOptionalTerm(String term) {
    optionalTerms.remove(term);
  }

  Future<void> submit() async {
    final clientId = clientIdController.text.trim();
    final municipalityId = municipalityIdController.text.trim();
    if (clientId.isEmpty) {
      Get.snackbar('Client required', 'Enter the client user id.');
      return;
    }

    final annualIncrement = double.tryParse(annualIncrementController.text.trim());
    if (annualIncrement == null) {
      Get.snackbar('Invalid increment', 'Enter a valid annual increment percent.');
      return;
    }

    final recurringCharges = <ContractCharge>[];
    for (final item in charges) {
      final label = item.label.text.trim();
      final amount = double.tryParse(item.amountController.text.trim());
      if (label.isEmpty || amount == null) {
        Get.snackbar(
          'Incomplete charges',
          'Each recurring charge needs a label and amount.',
        );
        return;
      }
      recurringCharges.add(
        ContractCharge(
          label: label,
          amount: amount,
          isAutoIncrement: item.isAutoIncrement.value,
        ),
      );
    }

    ContractCharge? rentCharge;
    for (final item in recurringCharges) {
      if (item.label.toLowerCase().contains('rent')) {
        rentCharge = item;
        break;
      }
    }
    if (rentCharge == null) {
      Get.snackbar('Rent required', 'Add a monthly rent charge before saving.');
      return;
    }

    isSubmitting.value = true;
    try {
      await _overviewController.createContract(
        CreateContractRequest(
          clientId: clientId,
          municipalityId: municipalityId,
          startDate: startDate.value,
          endDate: endDate.value,
          monthlyRent: rentCharge.amount,
          annualIncrementPercent: annualIncrement,
          recurringCharges: recurringCharges,
          optionalTerms: optionalTerms.toList(),
        ),
      );
      Get.back();
      Get.snackbar(
        'Contract shared',
        'The contract was created and sent to the client notification channel.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    clientIdController.dispose();
    municipalityIdController.dispose();
    annualIncrementController.dispose();
    termController.dispose();
    for (final item in charges) {
      item.dispose();
    }
    super.onClose();
  }
}
