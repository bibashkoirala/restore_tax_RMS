import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/app_bindings.dart';
import 'app/routes/app_pages.dart';
import 'services/api_ledger_service.dart';
import 'services/ledger_service.dart';
import 'services/mock_ledger_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RtmsApp());
}

class RtmsApp extends StatelessWidget {
  const RtmsApp({
    super.key,
    this.ledgerService = const bool.fromEnvironment(
              'USE_MOCK_SERVICE',
              defaultValue: false,
            )
        ? const MockLedgerService()
        : const ApiLedgerService(),
  });

  final LedgerService ledgerService;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RTMS',
      theme: AppTheme.governmentTheme,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(ledgerService),
      initialRoute: AppPages.login,
      getPages: AppPages.routes,
    );
  }
}
