import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/finance_provider.dart';
import '../../models/budget.dart';
import '../../widgets/app_drawer.dart';
import 'add_budget_modal.dart';
import 'add_monthly_budget_modal.dart';

import '../notifications/notif.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    // Fix visual bug: fetch all monthly budgets and current month data on load
    final financeData = context.read<FinanceProvider>();
    Future.microtask(() async {
      await financeData.fetchAllMonthlyBudgets();
      await financeData.fetchBudgets(month: financeData.selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final budgets = financeData.budgets;
    final monthlyBudget = financeData.monthlyBudget;
    final allMonthlyBudgets = financeData.allMonthlyBudgets;
    final selectedMonth = financeData.selectedMonth;

    final totalCategoryLimits = budgets.fold<double>(0.0, (sum, item) => sum + item.limit);
    final displayLimit = monthlyBudget != null 
        ? (monthlyBudget.limit - totalCategoryLimits).clamp(0.0, double.infinity) 
        : 0.0;
    final displayPercentage = monthlyBudget != null && displayLimit > 0 
        ? (monthlyBudget.spent / displayLimit) 
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(currentIndex: 2),
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month Chips List
          if (allMonthlyBudgets.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allMonthlyBudgets.length,
                itemBuilder: (context, index) {
                  final budget = allMonthlyBudgets[index];
                  final isSelected = budget.month == selectedMonth;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(budget.month),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          financeData.setSelectedMonth(budget.month);
                        }
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          if (allMonthlyBudgets.isNotEmpty) const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddMonthlyBudgetModal(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Buat Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: monthlyBudget != null ? () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddBudgetModal(),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (monthlyBudget == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada Budget Bulanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Buat budget bulanan terlebih dahulu untuk mulai mengatur pengeluaran Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else ...[
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(
                            displayPercentage >= 1.0 ? 'MELEBIHI' : displayPercentage >= 0.8 ? 'PERINGATAN' : 'AMAN',
                            displayPercentage >= 1.0 ? AppTheme.danger : displayPercentage >= 0.8 ? AppTheme.warning : AppTheme.success,
                          ),
                          const SizedBox(width: 4),
                          // Edit Monthly Budget
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddMonthlyBudgetModal(
                                  monthlyBudgetToEdit: monthlyBudget,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                            ),
                          ),
                          // Delete Monthly Budget
                          InkWell(
                            onTap: () => _confirmDeleteMonthlyBudget(context, financeData, monthlyBudget),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormat.convertToIdr(monthlyBudget.spent),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'dari ${CurrencyFormat.convertToIdr(displayLimit)}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${(displayPercentage * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: displayPercentage > 1.0 ? 1.0 : displayPercentage,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        displayPercentage >= 1.0 ? AppTheme.danger : displayPercentage >= 0.8 ? AppTheme.warning : AppTheme.success,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(displayPercentage * 100).toStringAsFixed(1)}% terpakai', style: const TextStyle(fontSize: 12)),
                      const Text('', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (displayPercentage < 0.8)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text('Pengeluaranmu masih aman ya!', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            
            // Category Budgets
            ...budgets.map((budget) => _buildBudgetCard(context, budget, financeData)),
          ],
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

  void _confirmDeleteMonthlyBudget(BuildContext context, FinanceProvider financeData, MonthlyBudget budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Budget Bulanan'),
        content: Text('Apakah Anda yakin ingin menghapus budget bulan ${budget.month}? Semua kategori budget di bulan ini juga akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final success = await financeData.deleteMonthlyBudget(budget.id, budget.month);
              if (!mounted) return;
              Navigator.pop(context); // close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Budget bulanan berhasil dihapus' : 'Gagal menghapus budget bulanan'),
                  backgroundColor: success ? AppTheme.success : AppTheme.danger,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategoryBudget(BuildContext context, FinanceProvider financeData, Budget budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Budget Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus budget kategori ${budget.category}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final success = await financeData.deleteCategoryBudget(budget.id, financeData.selectedMonth);
              if (!mounted) return;
              Navigator.pop(context); // close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Budget kategori berhasil dihapus' : 'Gagal menghapus budget kategori'),
                  backgroundColor: success ? AppTheme.success : AppTheme.danger,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget, FinanceProvider financeData) {
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
              const SizedBox(width: 4),
              // Edit Category Budget
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddBudgetModal(budgetToEdit: budget),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                ),
              ),
              // Delete Category Budget
              InkWell(
                onTap: () => _confirmDeleteCategoryBudget(context, financeData, budget),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                ),
              ),
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
              Text('${(budget.percentage * 100).toInt()}%', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
