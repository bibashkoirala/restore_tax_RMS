class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.contractCode,
    this.transactionReference,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? contractCode;
  final String? transactionReference;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'].toString(),
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['notification_type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      contractCode: json['contract_code'] as String?,
      transactionReference: json['transaction_reference'] as String?,
    );
  }
}
