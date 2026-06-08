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

  double get percentage => limit > 0 ? (spent / limit) : 0;
  double get remaining => limit - spent;
}
