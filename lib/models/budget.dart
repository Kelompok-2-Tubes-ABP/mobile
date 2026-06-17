class Budget {
  final String id;
  final String category;
  final double limit;
  double spent;
  
  Budget({
    required this.id,
    required this.category,
    required this.limit,
    this.spent = 0.0,
  });

  factory Budget.fromApiJson(Map<String, dynamic> json) {
    final budgetData = json['budget'] ?? json;
    return Budget(
      id: budgetData['id'] ?? '',
      category: budgetData['category'] ?? '',
      limit: (budgetData['limit'] ?? 0).toDouble(),
      spent: (budgetData['spent'] ?? 0).toDouble(),
    );
  }

  double get percentage => limit > 0 ? (spent / limit) : 0;
  double get remaining => limit - spent;
}

class MonthlyBudget {
  final String id;
  final String month;
  final double limit;
  double spent;

  MonthlyBudget({
    required this.id,
    required this.month,
    required this.limit,
    this.spent = 0.0,
  });

  factory MonthlyBudget.fromApiJson(Map<String, dynamic> json) {
    final budgetData = json['budget'] ?? json;
    return MonthlyBudget(
      id: budgetData['id'] ?? '',
      month: budgetData['month'] ?? '',
      limit: (budgetData['limit'] ?? 0).toDouble(),
      spent: (json['spending'] ?? budgetData['spent'] ?? 0).toDouble(),
    );
  }

  double get percentage => limit > 0 ? (spent / limit) : 0;
  double get remaining => limit - spent;
}
