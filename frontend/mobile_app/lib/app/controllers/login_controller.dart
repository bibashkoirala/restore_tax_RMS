import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'overview_controller.dart';

class LoginController extends GetxController {
  LoginController(this._overviewController);

  final OverviewController _overviewController;
  final usernameController = TextEditingController(text: '1');

  void submit() {
    final username = _normalizeUsername(usernameController.text.trim());
    if (username.isEmpty) {
      Get.snackbar('Username required', 'Enter a username to continue.');
      return;
    }
    _overviewController.login(username);
  }

  String _normalizeUsername(String value) {
    switch (value) {
      case '1':
        return 'ward5_admin';
      case '2':
        return 'sita_client';
      case '3':
        return 'hari_landlord';
      default:
        return value;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    super.onClose();
  }
}
