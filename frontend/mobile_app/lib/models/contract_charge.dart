class ContractCharge {
  const ContractCharge({
    required this.label,
    required this.amount,
    required this.isAutoIncrement,
  });

  final String label;
  final double amount;
  final bool isAutoIncrement;

  factory ContractCharge.fromJson(Map<String, dynamic> json) {
    return ContractCharge(
      label: json['label'] as String? ?? '',
      amount: double.parse(json['amount'].toString()),
      isAutoIncrement: json['is_auto_increment'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'amount': amount,
      'is_auto_increment': isAutoIncrement,
    };
  }
}
