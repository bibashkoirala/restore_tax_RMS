class AuditLog {
  const AuditLog({
    required this.id,
    required this.actor,
    required this.action,
    required this.createdAt,
    required this.metadata,
  });

  final String id;
  final String actor;
  final String action;
  final DateTime createdAt;
  final Map<String, String> metadata;
}
