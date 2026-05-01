import 'package:get/get.dart';

import '../../models/party.dart';

class SessionController extends GetxController {
  final user = Rxn<Party>();

  String get username => user.value?.username ?? '';
  bool get isLoggedIn => user.value != null;

  void signIn(Party party) {
    user.value = party;
  }

  void signOut() {
    user.value = null;
  }
}
