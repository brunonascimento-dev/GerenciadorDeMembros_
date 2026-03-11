class FinancialEntry {
  const FinancialEntry({
    required this.description,
    required this.amount,
  });

  final String description;
  final double amount;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
    };
  }

  factory FinancialEntry.fromMap(Map<String, dynamic> map) {
    return FinancialEntry(
      description: (map['description'] ?? '').toString(),
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse((map['amount'] ?? '').toString()) ?? 0,
    );
  }
}
