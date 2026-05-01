import 'package:get/get.dart';

import '../../services/ledger_service.dart';
import '../controllers/login_controller.dart';
import '../controllers/overview_controller.dart';
import '../controllers/session_controller.dart';

class AppBindings extends Bindings {
  AppBindings(this.ledgerService);

  final LedgerService ledgerService;

  @override
  void dependencies() {
    Get.put<LedgerService>(ledgerService, permanent: true);
    Get.put(SessionController(), permanent: true);
    Get.put(
      OverviewController(
        Get.find<LedgerService>(),
        Get.find<SessionController>(),
      ),
      permanent: true,
    );
    Get.lazyPut(() => LoginController(Get.find<OverviewController>()));
  }
}
