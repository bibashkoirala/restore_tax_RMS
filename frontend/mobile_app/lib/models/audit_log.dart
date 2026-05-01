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
  final Map<String, dynamic> metadata;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    final actorJson = json['actor'] as Map<String, dynamic>?;
    return AuditLog(
      id: json['id'].toString(),
      actor: actorJson?['name'] as String? ?? 'Unknown Actor',
      action: json['action'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
