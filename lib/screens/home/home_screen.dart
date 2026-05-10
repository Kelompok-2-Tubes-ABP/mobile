import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction.dart' as t;
import '../../models/budget.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final authData = context.watch<AuthProvider>();
    final user = authData.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      drawer: Drawer(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Drawer Header (FinanceApp with close button)
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FinanceApp',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // User Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'O', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Orcas', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(CurrencyFormat.convertToIdr(financeData.totalSaldo), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Menus
            _buildDrawerItem(context, Icons.dashboard_customize, 'Dashboard', isSelected: true),
            _buildDrawerItem(context, Icons.account_balance_wallet_outlined, 'Transaksi'),
            _buildDrawerItem(context, Icons.show_chart, 'Budget'),
            _buildDrawerItem(context, Icons.track_changes, 'Tabungan'),
            _buildDrawerItem(context, Icons.chat_bubble_outline, 'AI Chatbot'),
            _buildDrawerItem(context, Icons.settings_outlined, 'Pengaturan'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                  Stack(
                    children: [
                      const Icon(Icons.notifications_none, size: 32),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.danger,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
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
                        const Icon(Icons.visibility_outlined, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormat.convertToIdr(financeData.totalSaldo),
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
                                      CurrencyFormat.convertToIdr(financeData.totalPemasukan),
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
                                      CurrencyFormat.convertToIdr(financeData.totalPengeluaran),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(Icons.add, 'Transaksi'),
                    const SizedBox(width: 16),
                    _buildActionButton(Icons.track_changes, 'Goals'),
                    const SizedBox(width: 16),
                    _buildActionButton(Icons.bar_chart, 'Budget'),
                    const SizedBox(width: 16),
                    _buildActionButton(Icons.trending_up, 'Investasi'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaksi Terakhir', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Lihat Semua'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              
              ...financeData.transactions.take(3).map((tx) => _buildTransactionItem(context, tx)).toList(),

              const SizedBox(height: 24),
              _buildBudgetSection(financeData),
              const SizedBox(height: 24),
              _buildSavingsTargetSection(),
              const SizedBox(height: 24),
              _buildBiggestExpenseSection(financeData),
              const SizedBox(height: 24),
              _buildInvestmentPortfolioSection(),
              const SizedBox(height: 32),
              _buildAITalkButton(),
              const SizedBox(height: 80), // Padding for FAB

            ],
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

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : AppTheme.textPrimary),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildBudgetSection(FinanceProvider financeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Budget Bulan Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: financeData.budgets.take(3).map((budget) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: budget.percentage,
                      backgroundColor: Colors.grey.shade200,
                      color: budget.percentage >= 1.0 ? AppTheme.danger : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${CurrencyFormat.convertToIdr(budget.spent)} / ${CurrencyFormat.convertToIdr(budget.limit)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsTargetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Tabungan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Beli Mobil Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Terkumpul Rp 50.000.000 dari Rp 200.000.000', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.25,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiggestExpenseSection(FinanceProvider financeData) {
    // Find biggest expense
    final expenses = financeData.transactions.where((tx) => tx.type == t.TransactionType.pengeluaran).toList();
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    final biggestExpense = expenses.isNotEmpty ? expenses.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pengeluaran Terbesar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (biggestExpense != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
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

  Widget _buildInvestmentPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Portofolio Investasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Investasi', style: TextStyle(color: Colors.grey)),
                  Text('+12.5%', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rp 15.000.000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInvestmentItem('Reksadana', '60%', Colors.blue),
                  _buildInvestmentItem('Saham', '30%', Colors.orange),
                  _buildInvestmentItem('Emas', '10%', Colors.amber),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentItem(String label, String percent, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label $percent', style: const TextStyle(fontSize: 12)),
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

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
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
