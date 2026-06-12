class SavingsGoal {
  final String id;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final String category;
  final int priority;
  final String status;
  final double progress;
  final double monthlyNeeded;
  final bool isOnTrack;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.targetDate,
    required this.category,
    required this.priority,
    required this.status,
    required this.progress,
    required this.monthlyNeeded,
    required this.isOnTrack,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    // Check if the goal object is nested under "goal" key (from list/get endpoints)
    final goalData = json['goal'] ?? json;
    final double target = (goalData['target_amount'] ?? 0.0).toDouble();
    final double current = (goalData['current_amount'] ?? 0.0).toDouble();
    final double progressVal = json['progress'] != null 
        ? (json['progress'] as num).toDouble() 
        : (target > 0 ? (current / target) * 100 : 0.0);

    return SavingsGoal(
      id: goalData['id'] ?? '',
      name: goalData['name'] ?? '',
      description: goalData['description'] ?? '',
      targetAmount: target,
      currentAmount: current,
      startDate: DateTime.tryParse(goalData['start_date'] ?? '') ?? DateTime.now(),
      targetDate: DateTime.tryParse(goalData['target_date'] ?? '') ?? DateTime.now(),
      category: goalData['category'] ?? '',
      priority: goalData['priority'] ?? 2,
      status: goalData['status'] ?? 'active',
      progress: progressVal,
      monthlyNeeded: (json['monthly_needed'] ?? 0.0).toDouble(),
      isOnTrack: json['on_track'] ?? true,
    );
  }

  double get remaining => targetAmount - currentAmount;
}

class SavingsSummary {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final double totalTarget;
  final double totalSaved;
  final double overallProgress;

  SavingsSummary({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.totalTarget,
    required this.totalSaved,
    required this.overallProgress,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) {
    return SavingsSummary(
      totalGoals: json['total_goals'] ?? 0,
      activeGoals: json['active_goals'] ?? 0,
      completedGoals: json['completed_goals'] ?? 0,
      totalTarget: (json['total_target'] ?? 0.0).toDouble(),
      totalSaved: (json['total_saved'] ?? 0.0).toDouble(),
      overallProgress: (json['overall_progress'] ?? 0.0).toDouble(),
    );
  }

  factory SavingsSummary.empty() {
    return SavingsSummary(
      totalGoals: 0,
      activeGoals: 0,
      completedGoals: 0,
      totalTarget: 0.0,
      totalSaved: 0.0,
      overallProgress: 0.0,
    );
  }
}
