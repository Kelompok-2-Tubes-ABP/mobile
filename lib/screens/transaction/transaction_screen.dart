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
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String selectedMonth = 'Mei';
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

    Future.microtask(() async {
      await context.read<FinanceProvider>().fetchTransactions();

      await context.read<FinanceProvider>().fetchBudgets();

      await context.read<FinanceProvider>().fetchBudgetSummary();

      await context.read<FinanceProvider>().fetchAllBudgetSpending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(currentIndex: 1),
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
          // Month Selector
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: months.length,
              itemBuilder: (context, index) {
                bool isSelected = months[index] == selectedMonth;
                return GestureDetector(
                  onTap: () => setState(() => selectedMonth = months[index]),
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
                      months[index],
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
                // Summary Cards
                _buildSummaryCard(
                  'Pemasukan',
                  financeData.totalPemasukan,
                  AppTheme.success,
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  'Pengeluaran',
                  financeData.totalPengeluaran,
                  AppTheme.danger,
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  'Selisih',
                  financeData.totalSaldo,
                  financeData.totalSaldo >= 0
                      ? AppTheme.success
                      : AppTheme.danger,
                  isDiff: true,
                ),

                const SizedBox(height: 24),

                // Category Filters
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      bool isSelected = categories[index] == selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(
                          () => selectedCategory = categories[index],
                        ),
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
                              categories[index],
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

                // Grouped Transactions
                _buildTransactionList(financeData.transactions),
              ],
            ),
          ),
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
        },
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
  }) {
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
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${isDiff && amount > 0 ? '+' : ''}${CurrencyFormat.convertToIdr(amount)}',
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

    final selectedMonthNumber = monthMap[selectedMonth];

    print('BULAN DIPILIH: $selectedMonth');
    print('MONTH NUMBER: $selectedMonthNumber');

    for (var tx in transactions) {
      print('${tx.title} => ${tx.date} => month ${tx.date.month}');
    }

    List<t.Transaction> filtered = transactions.where((tx) {
      final matchesMonth = tx.date.month == selectedMonthNumber;
      final matchesCategory = selectedCategory == 'All' || tx.category == selectedCategory;
      print('FILTERED MONTH CHECK: tx.date.month=${tx.date.month} vs selectedMonthNumber=$selectedMonthNumber => $matchesMonth');
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
      children: filtered
          .map((tx) => _buildTransactionItem(context, tx))
          .toList(),
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

  void _confirmDeleteTransaction(BuildContext context, t.Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text('Apakah Anda yakin ingin menghapus transaksi "${tx.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog konfirmasi
              
              // Tampilkan dialog loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              context.read<FinanceProvider>().deleteTransaction(tx.id).then((success) {
                Navigator.pop(context); // Tutup dialog loading
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi berhasil dihapus')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus transaksi')),
                  );
                }
              });
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, t.Transaction tx) {
    bool isPemasukan = tx.type == t.TransactionType.pemasukan;
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
                      color: isPemasukan
                          ? AppTheme.success.withOpacity(0.1)
                          : AppTheme.warning.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPemasukan ? Icons.arrow_upward : _getCategoryIcon(tx.category),
                      color: isPemasukan ? AppTheme.success : AppTheme.warning,
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
                        Text(
                          '${tx.category} • ${tx.paymentMethod}',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${isPemasukan ? '+' : ''}${CurrencyFormat.convertToIdr(tx.amount)}',
                        style: TextStyle(
                          color: isPemasukan ? AppTheme.success : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.time,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan':
        return Icons.restaurant;
      case 'Transportasi':
        return Icons.directions_car;
      case 'Belanja':
        return Icons.shopping_bag;
      case 'Tagihan':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }
}
