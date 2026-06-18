import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction.dart' as t;
import '../../widgets/app_drawer.dart';
import 'add_transaction_modal.dart';
import 'edit_transaction_modal.dart';

class TransactionScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const TransactionScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late String selectedMonth;
  String selectedCategory = 'All';

  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final List<String> categories = [
    'All',
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Kesehatan',
    'Hiburan',
    'Investasi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();

    selectedMonth = _currentMonthLabel();

    Future.microtask(() async {
      final provider = context.read<FinanceProvider>();

      await provider.fetchMonthlySummary(
        month: _monthLabelToBackend(selectedMonth),
      );

      await provider.fetchTransactions();
      await provider.fetchBudgets();
      await provider.fetchBudgetSummary();
      await provider.fetchAllBudgetSpending();
    });
  }

  String _currentMonthLabel() {
    switch (DateTime.now().month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return 'Juni';
    }
  }

  String _monthLabelToBackend(String month) {
    switch (month) {
      case 'Jan':
        return 'January';
      case 'Feb':
        return 'February';
      case 'Mar':
        return 'March';
      case 'Apr':
        return 'April';
      case 'Mei':
        return 'May';
      case 'Juni':
        return 'June';
      case 'Juli':
        return 'July';
      case 'Agustus':
        return 'August';
      case 'September':
        return 'September';
      case 'Oktober':
        return 'October';
      case 'November':
        return 'November';
      case 'Desember':
        return 'December';
      default:
        return 'June';
    }
  }

  Future<void> _changeMonth(String month) async {
    setState(() {
      selectedMonth = month;
      selectedCategory = 'All';
    });

    final provider = context.read<FinanceProvider>();

    await provider.fetchMonthlySummary(
      month: _monthLabelToBackend(month),
    );

    await provider.fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: AppDrawer(
        onNavigate: widget.onNavigate,
        currentIndex: 1,
      ),
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddTransaction(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final isSelected = month == selectedMonth;

                return GestureDetector(
                  onTap: () => _changeMonth(month),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      month,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(
                  'Pemasukan',
                  financeData.monthlyIncome,
                  AppTheme.success,
                  isLoading: financeData.isLoadingMonthlySummary,
                ),

                const SizedBox(height: 12),

                _buildSummaryCard(
                  'Pengeluaran',
                  financeData.monthlyOutcome,
                  AppTheme.danger,
                  isExpense: true,
                  isLoading: financeData.isLoadingMonthlySummary,
                ),

                const SizedBox(height: 12),

                _buildSummaryCard(
                  'Selisih',
                  financeData.monthlyNet,
                  financeData.monthlyNet >= 0
                      ? AppTheme.success
                      : AppTheme.danger,
                  isDiff: true,
                  isLoading: financeData.isLoadingMonthlySummary,
                ),

                if (financeData.monthlySummaryError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    financeData.monthlySummaryError,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                _buildTransactionList(financeData.transactions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction(BuildContext context) {
    print('TRANSACTION SCREEN MONTH: $selectedMonth');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(selectedMonth: selectedMonth),
    );
  }

  Widget _buildSummaryCard(
      String title,
      double amount,
      Color color, {
        bool isDiff = false,
        bool isExpense = false,
        bool isLoading = false,
      }) {
    String prefix = '';

    if (isExpense && amount > 0) {
      prefix = '-';
    } else if (isDiff && amount > 0) {
      prefix = '+';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (isLoading)
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              '$prefix${CurrencyFormat.convertToIdr(amount.abs())}',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<t.Transaction> transactions) {
    final monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };

    final selectedMonthNumber = monthMap[selectedMonth] ?? DateTime.now().month;

    print('BULAN DIPILIH: $selectedMonth');
    print('MONTH NUMBER: $selectedMonthNumber');

    for (var tx in transactions) {
      print('${tx.title} => ${tx.date} => month ${tx.date.month}');
    }

    final filtered = transactions.where((tx) {
      final matchesMonth = tx.date.month == selectedMonthNumber;
      final matchesCategory =
          selectedCategory == 'All' || tx.category == selectedCategory;

      print(
        'FILTERED MONTH CHECK: tx.date.month=${tx.date.month} vs selectedMonthNumber=$selectedMonthNumber => $matchesMonth',
      );

      return matchesMonth && matchesCategory;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Tidak ada transaksi'),
        ),
      );
    }

    return Column(
      children: filtered.map((tx) => _buildTransactionItem(context, tx)).toList(),
    );
  }

  void _showEditTransaction(BuildContext context, t.Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTransactionModal(transaction: tx),
    );
  }

  Future<void> _confirmDeleteTransaction(
      BuildContext parentContext,
      t.Transaction tx,
      ) async {
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi "${tx.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    BuildContext? loadingContext;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
        loadingContext = ctx;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    bool success = false;

    try {
      print('DELETE TRANSACTION ID: ${tx.id}');

      success = await parentContext
          .read<FinanceProvider>()
          .deleteTransaction(tx.id)
          .timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('DELETE TRANSACTION TIMEOUT');
          return false;
        },
      );
    } catch (e) {
      print('ERROR DELETE TRANSACTION SCREEN: $e');
      success = false;
    } finally {
      if (loadingContext != null && Navigator.of(loadingContext!).canPop()) {
        Navigator.of(loadingContext!).pop();
      } else if (mounted) {
        Navigator.of(parentContext, rootNavigator: true).maybePop();
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Transaksi berhasil dihapus'
              : 'Gagal menghapus transaksi',
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, t.Transaction tx) {
    final isPemasukan = tx.type == t.TransactionType.pemasukan;

    final amountPrefix = isPemasukan ? '+' : '-';
    final amountColor = isPemasukan ? AppTheme.success : AppTheme.danger;
    final iconColor = isPemasukan ? AppTheme.success : AppTheme.danger;
    final iconBackgroundColor = isPemasukan
        ? AppTheme.success.withOpacity(0.1)
        : AppTheme.danger.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showEditTransaction(context, tx),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPemasukan
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: iconColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          tx.category,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$amountPrefix${CurrencyFormat.convertToIdr(tx.amount.abs())}',
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.time,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.danger,
                    ),
                    onPressed: () => _confirmDeleteTransaction(context, tx),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}