import 'package:get/get.dart';

import '../controllers/create_contract_controller.dart';
import '../views/home_page.dart';
import '../views/create_contract_page.dart';
import '../views/login_page.dart';

class AppPages {
  static const login = '/login';
  static const home = '/home';
  static const createContract = '/contracts/create';

  static final routes = [
    GetPage(name: login, page: LoginPage.new),
    GetPage(name: home, page: HomePage.new),
    GetPage(
      name: createContract,
      page: CreateContractPage.new,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => CreateContractController(Get.find()),
        ),
      ),
    ),
  ];
}
