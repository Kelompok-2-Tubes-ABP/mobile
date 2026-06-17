import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction.dart' as t;
import '../../models/savings_goal.dart';
import '../../widgets/app_drawer.dart';
import '../notifications/notif.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isObscured = false;

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final authData = context.watch<AuthProvider>();
    final user = authData.currentUser;

    print("TOTAL INCOME: ${financeData.quickStats.monthIncome}");
    print("TOTAL EXPENSE: ${financeData.quickStats.monthSpending}");
    print("NET BALANCE: ${financeData.quickStats.netWorth}");
    
    final double totalSaldo = financeData.quickStats.monthIncome - financeData.quickStats.monthSpending;
    print("FLUTTER: nilai yang dipakai widget Total Saldo = $totalSaldo");

    for (var tx in financeData.transactions) {
      print("TX TITLE: ${tx.title} TYPE: ${tx.type} AMOUNT: ${tx.amount}");
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      drawer: AppDrawer(onNavigate: widget.onNavigate, currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await financeData.fetchTransactions();
            await financeData.fetchBudgets();
            await financeData.fetchQuickStats();
            await financeData.fetchSavingsGoals();
            await financeData.fetchSavingsGoalSummary();
            await financeData.fetchPortfolio();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Total Saldo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Halo, ${user?.name ?? 'Orcas'}!',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Text('👋', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatUtil.formatDayDate(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotifPage()),
                        );
                      },
                      child: Consumer<NotificationProvider>(
                        builder: (context, notifProvider, child) {
                          return Stack(
                            children: [
                              const Icon(Icons.notifications_none, size: 32),
                              if (notifProvider.unreadCount > 0)
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.danger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      notifProvider.unreadCount > 9 ? '9+' : notifProvider.unreadCount.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                            ],
                          );
                        },
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // Total Saldo Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Saldo', style: TextStyle(color: Colors.white70)),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isObscured = !_isObscured;
                              });
                            },
                            child: Icon(
                              _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isObscured ? 'Rp ********' : CurrencyFormat.convertToIdr(totalSaldo),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(
                                        _isObscured ? 'Rp ********' : CurrencyFormat.convertToIdr(financeData.quickStats.monthIncome),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(
                                        _isObscured ? 'Rp ********' : CurrencyFormat.convertToIdr(financeData.quickStats.monthSpending),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(Icons.add, 'Transaksi', () {
                      if (widget.onNavigate != null) widget.onNavigate!(1);
                    }),
                    _buildActionButton(Icons.track_changes, 'Goals', () {
                      if (widget.onNavigate != null) widget.onNavigate!(3);
                    }),
                    _buildActionButton(Icons.bar_chart, 'Budget', () {
                      if (widget.onNavigate != null) widget.onNavigate!(2);
                    }),
                    _buildActionButton(Icons.trending_up, 'Investasi', () {
                      if (widget.onNavigate != null) widget.onNavigate!(3);
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // Budget Bulan Ini
                _buildBudgetSection(financeData),
                const SizedBox(height: 24),

                // Target Tabungan
                _buildSavingsTargetSection(financeData),
                const SizedBox(height: 24),

                // Pengeluaran Terbesar
                _buildBiggestExpenseSection(financeData),
                const SizedBox(height: 24),

                // Portofolio Investasi
                _buildInvestmentPortfolioSection(financeData),
                const SizedBox(height: 24),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transaksi Terakhir', style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () {
                        if (widget.onNavigate != null) widget.onNavigate!(1);
                      },
                      child: const Text('Lihat Semua'),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                ...financeData.transactions.take(3).map((tx) => _buildTransactionItem(context, tx)).toList(),

                const SizedBox(height: 24),
                // Tanya AI Button
                _buildAITalkButton(),
                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: AppTheme.primaryColor, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(FinanceProvider financeData) {
    double totalLimit = financeData.budgets.fold(0, (sum, item) => sum + item.limit);
    double totalSpent = financeData.budgets.fold(0, (sum, item) => sum + item.spent);
    double percentage = totalLimit > 0 ? (totalSpent / totalLimit) : 0;
    bool isSafe = percentage <= 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Budget Bulan Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mei 2026', style: TextStyle(color: AppTheme.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSafe ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isSafe ? 'Pengeluaranmu masih aman' : 'Mendekati batas',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSafe ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: isSafe ? AppTheme.primaryColor : AppTheme.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormat.convertToIdr(totalSpent),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'dari ${CurrencyFormat.convertToIdr(totalLimit)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsTargetSection(FinanceProvider financeData) {
    final goals = financeData.savingsGoals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Tabungan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: financeData.isLoadingSavings
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : goals.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Belum ada target tabungan.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(goals.length, (index) {
                        final SavingsGoal goal = goals[index];
                        final isLast = index == goals.length - 1;
                        return Column(
                          children: [
                            _buildSavingsItem(
                              _getGoalIcon(goal.category),
                              _getGoalColor(goal.category),
                              goal.name,
                              goal.currentAmount,
                              goal.targetAmount,
                              goal.progress,
                              goal.remaining,
                            ),
                            if (!isLast)
                              const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
                          ],
                        );
                      }),
                    ),
        ),
      ],
    );
  }

  Widget _buildSavingsItem(
    IconData icon,
    Color color,
    String title,
    double current,
    double target,
    double progress,
    double remaining,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Terkumpul ${CurrencyFormat.convertToIdr(current)} dari ${CurrencyFormat.convertToIdr(target)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                remaining > 0
                    ? 'Sisa ${CurrencyFormat.convertToIdr(remaining)} lagi'
                    : 'Target tercapai! 🎉',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: remaining > 0 ? AppTheme.textSecondary : AppTheme.success,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (target > 0 ? (current / target) : 0.0).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kendaraan':
      case 'mobil':
      case 'motor':
        return Icons.directions_car;
      case 'elektronik':
      case 'gadget':
      case 'laptop':
      case 'hp':
        return Icons.laptop_mac;
      case 'rumah':
      case 'properti':
        return Icons.home;
      case 'pendidikan':
      case 'sekolah':
      case 'kuliah':
        return Icons.school;
      case 'liburan':
      case 'wisata':
      case 'traveling':
        return Icons.flight;
      case 'darurat':
      case 'kesehatan':
        return Icons.emergency;
      default:
        return Icons.savings;
    }
  }

  Color _getGoalColor(String category) {
    switch (category.toLowerCase()) {
      case 'kendaraan':
      case 'mobil':
      case 'motor':
        return Colors.blue;
      case 'elektronik':
      case 'gadget':
      case 'laptop':
      case 'hp':
        return Colors.orange;
      case 'rumah':
      case 'properti':
        return Colors.green;
      case 'pendidikan':
      case 'sekolah':
      case 'kuliah':
        return Colors.purple;
      case 'liburan':
      case 'wisata':
      case 'traveling':
        return Colors.teal;
      case 'darurat':
      case 'kesehatan':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildBiggestExpenseSection(FinanceProvider financeData) {
    final expenses = financeData.transactions.where((tx) => tx.type == t.TransactionType.pengeluaran).toList();
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    final biggestExpense = expenses.isNotEmpty ? expenses.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pengeluaran Terbesar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Perhatian', style: TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (biggestExpense != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.danger.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(biggestExpense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(biggestExpense.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormat.convertToIdr(biggestExpense.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger, fontSize: 16),
                ),
              ],
            ),
          )
        else
          const Text('Belum ada pengeluaran.'),
      ],
    );
  }

  Widget _buildInvestmentPortfolioSection(FinanceProvider financeData) {
    final summary = financeData.investmentSummary;
    final totalInvested = summary.totalValue > 0 ? summary.totalValue : financeData.totalInvestment;
    final totalProfit = summary.totalValue > 0 ? summary.gainLoss : financeData.investments.fold(0.0, (sum, item) => sum + item.gainLoss);
    final double totalCost = summary.totalValue > 0 ? summary.totalCost : financeData.investments.fold(0.0, (sum, item) => sum + item.totalCost);
    final totalProfitPercentage = summary.totalValue > 0 ? summary.gainLossPercent : (totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0);
    bool isPositive = totalProfitPercentage >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Portofolio Investasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Nilai', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Row(
                    children: [
                      const Text('Keuntungan', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${totalProfitPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isPositive ? AppTheme.success : AppTheme.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormat.convertToIdr(totalInvested),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${totalProfit >= 0 ? '+' : ''}${CurrencyFormat.convertToIdr(totalProfit)}',
                    style: TextStyle(color: isPositive ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Bar Chart Mockup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(10, (index) {
                  double height = 20.0 + (index * 4) + (index % 3 * 2);
                  return Container(
                    width: 20,
                    height: height,
                    decoration: BoxDecoration(
                      color: isPositive ? AppTheme.success.withOpacity(0.3) : AppTheme.danger.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  );
                }),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAITalkButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Tanya AI tentang keuangan mu',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, t.Transaction tx) {
    bool isPemasukan = tx.type == t.TransactionType.pemasukan;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPemasukan ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPemasukan ? Icons.arrow_downward : Icons.restaurant,
              color: isPemasukan ? AppTheme.success : AppTheme.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${tx.category} • ${DateFormatUtil.formatDate(tx.date)}', 
                     style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isPemasukan ? '+' : ''}${CurrencyFormat.convertToIdr(tx.amount)}',
            style: TextStyle(
              color: isPemasukan ? AppTheme.success : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
