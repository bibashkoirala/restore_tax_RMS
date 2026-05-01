import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/overview_controller.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OverviewController>();

    return Obx(() {
      final notifications = controller.notifications;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Landlords receive contract approvals and claim alerts. Clients receive payment approvals. Municipality stays informed without changing payments.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...notifications.map(
            (item) => Card(
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.message),
                trailing: item.isRead
                    ? const Icon(Icons.done, color: Colors.green)
                    : const Icon(Icons.fiber_new, color: Colors.red),
              ),
            ),
          ),
          if (notifications.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No notifications yet.'),
              ),
            ),
        ],
      );
    });
  }
}
