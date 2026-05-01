import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/party.dart';
import '../controllers/overview_controller.dart';
import 'tabs/contracts_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/notifications_tab.dart';

class HomePage extends GetView<OverviewController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user;
      if (user == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('${user.name} - ${_roleLabel(user)}'),
          actions: [
            IconButton(
              onPressed: controller.refreshOverview,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: IndexedStack(
          index: controller.selectedTab.value,
          children: const [
            DashboardTab(),
            ContractsTab(),
            NotificationsTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.selectedTab.value,
          onDestinationSelected: controller.changeTab,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: user.isMunicipality ? 'Overview' : 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Contracts',
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications),
              label: user.isLandlord
                  ? 'Approvals'
                  : user.isClient
                  ? 'Updates'
                  : 'Alerts',
            ),
          ],
        ),
      );
    });
  }

  String _roleLabel(Party user) {
    if (user.isMunicipality) {
      return 'Municipality Admin';
    }
    if (user.isLandlord) {
      return 'Landlord Home';
    }
    return 'User Home';
  }
}
