class QuickStats {
  final double todaySpending;
  final double weekSpending;
  final double monthSpending;
  final double todayIncome;
  final double weekIncome;
  final double monthIncome;
  final double monthSavings;
  final int activeBills;
  final double upcomingBills;
  final double investmentValue;
  final double netWorth;

  QuickStats({
    required this.todaySpending,
    required this.weekSpending,
    required this.monthSpending,
    required this.todayIncome,
    required this.weekIncome,
    required this.monthIncome,
    required this.monthSavings,
    required this.activeBills,
    required this.upcomingBills,
    required this.investmentValue,
    required this.netWorth,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      todaySpending: (json['today_spending'] ?? 0).toDouble(),
      weekSpending: (json['week_spending'] ?? 0).toDouble(),
      monthSpending: (json['month_spending'] ?? 0).toDouble(),
      todayIncome: (json['today_income'] ?? 0).toDouble(),
      weekIncome: (json['week_income'] ?? 0).toDouble(),
      monthIncome: (json['month_income'] ?? 0).toDouble(),
      monthSavings: (json['month_savings'] ?? 0).toDouble(),
      activeBills: (json['active_bills'] ?? 0).toInt(),
      upcomingBills: (json['upcoming_bills'] ?? 0).toDouble(),
      investmentValue: (json['investment_value'] ?? 0).toDouble(),
      netWorth: (json['net_worth'] ?? 0).toDouble(),
    );
  }

  factory QuickStats.empty() {
    return QuickStats(
      todaySpending: 0,
      weekSpending: 0,
      monthSpending: 0,
      todayIncome: 0,
      weekIncome: 0,
      monthIncome: 0,
      monthSavings: 0,
      activeBills: 0,
      upcomingBills: 0,
      investmentValue: 0,
      netWorth: 0,
    );
  }
}
