import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import '../controllers/overview_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final overviewController = Get.find<OverviewController>();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'RTMS Record Management',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use 1 for municipality, 2 for client, or 3 for landlord to load the role-based app experience.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller.usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Role / Username',
                      hintText: '1 / 2 / 3 or existing username',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: overviewController.isLoading.value
                        ? null
                        : controller.submit,
                    child: overviewController.isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Role shortcuts: 1 = municipality, 2 = client, 3 = landlord.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
