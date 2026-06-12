import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/finance_provider.dart';
import '../../models/budget.dart';
import '../../widgets/app_drawer.dart';
import 'add_budget_modal.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final budgets = financeData.budgets;

    double totalLimit = budgets.fold(0, (sum, b) => sum + b.limit);
    double totalSpent = budgets.fold(0, (sum, b) => sum + b.spent);
    double totalPercentage = totalLimit > 0 ? (totalSpent / totalLimit) : 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(currentIndex: 2),
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Mei 2026', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddBudgetModal(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Budget', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Monthly Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Budget Bulanan', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildStatusBadge('AMAN', AppTheme.success),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormat.convertToIdr(totalSpent),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'dari ${CurrencyFormat.convertToIdr(totalLimit)}',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${(totalPercentage * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalPercentage,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(totalPercentage * 100).toStringAsFixed(1)}% terpakai', style: const TextStyle(fontSize: 12)),
                    const Text('18 hari tersisa', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Text('Pengeluaranmu masih aman 👍', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Category Budgets
          ...budgets.map((budget) => _buildBudgetCard(context, budget)),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          );
        }
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget) {
    Color statusColor = AppTheme.success;
    String statusText = 'Aman';
    
    if (budget.percentage >= 1.0) {
      statusColor = AppTheme.danger;
      statusText = 'Melebihi';
    } else if (budget.percentage >= 0.8) {
      statusColor = AppTheme.warning;
      statusText = 'Peringatan';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getCategoryIcon(budget.category), color: AppTheme.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(budget.category, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _buildStatusBadge(statusText.toUpperCase(), statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormat.convertToIdr(budget.spent)} / ${CurrencyFormat.convertToIdr(budget.limit)}',
                style: const TextStyle(fontSize: 14),
              ),
              Text('${(budget.percentage * 100).toInt()}%', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.percentage > 1.0 ? 1.0 : budget.percentage,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                budget.remaining >= 0 
                  ? 'Sisa ${CurrencyFormat.convertToIdr(budget.remaining)}'
                  : 'Lebih ${CurrencyFormat.convertToIdr(budget.spent - budget.limit)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan': return Icons.restaurant;
      case 'Transportasi': return Icons.directions_car;
      case 'Belanja': return Icons.shopping_bag;
      case 'Tagihan': return Icons.receipt;
      case 'Hiburan': return Icons.videogame_asset;
      case 'Kesehatan': return Icons.medical_services;
      default: return Icons.category;
    }
  }
}
