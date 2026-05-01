import 'contract.dart';
import 'notification_item.dart';
import 'party.dart';
import 'transaction_entry.dart';

class UserOverview {
  const UserOverview({
    required this.user,
    required this.contracts,
    required this.transactions,
    required this.notifications,
  });

  final Party user;
  final List<Contract> contracts;
  final List<TransactionEntry> transactions;
  final List<NotificationItem> notifications;

  factory UserOverview.fromJson(Map<String, dynamic> json) {
    return UserOverview(
      user: Party.fromJson(json['user'] as Map<String, dynamic>),
      contracts: (json['contracts'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Contract.fromJson)
          .toList(),
      transactions: (json['transactions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(TransactionEntry.fromJson)
          .toList(),
      notifications: (json['notifications'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList(),
    );
  }
}
