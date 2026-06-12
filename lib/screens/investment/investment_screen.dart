import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/finance_provider.dart';
import '../../models/investment.dart';
import '../../widgets/app_drawer.dart';
import 'add_investment_modal.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  String selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<FinanceProvider>().fetchPortfolio();
      }
    });
  }

  Future<void> _confirmDeleteInvestment(Investment item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Investasi'),
        content: Text('Apakah Anda yakin ingin menghapus investasi ${item.name} (${item.symbol})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final financeProvider = context.read<FinanceProvider>();
        final success = await financeProvider.deleteInvestment(item.id);
        if (!mounted) return;
        Navigator.pop(context); // Pop loading dialog
        
        if (success) {
          await financeProvider.fetchPortfolio();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Investasi ${item.name} berhasil dihapus')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus investasi dari server')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final allInvestments = financeData.investments;

    List<Investment> filteredInvestments = allInvestments;
    if (selectedFilter != 'Semua') {
      filteredInvestments = allInvestments.where((item) => item.type.toLowerCase() == selectedFilter.toLowerCase()).toList();
    }

    double totalValue;
    double totalProfit;
    double totalProfitPercentage;
    bool isPositive;

    if (selectedFilter == 'Semua' && financeData.investmentSummary.totalValue > 0) {
      totalValue = financeData.investmentSummary.totalValue;
      totalProfit = financeData.investmentSummary.gainLoss;
      totalProfitPercentage = financeData.investmentSummary.gainLossPercent;
      isPositive = totalProfitPercentage >= 0;
    } else {
      totalValue = filteredInvestments.fold(0, (sum, item) => sum + item.amount);
      totalProfit = 0;
      double initialValue = 0;
      for(var item in filteredInvestments) {
        double profitAmount = 0;
        if (item.profitPercentage != -100) {
          profitAmount = item.amount - (item.amount / (1 + (item.profitPercentage / 100)));
        } else {
          profitAmount = -item.amount;
        }
        totalProfit += profitAmount;
        initialValue += (item.amount / (1 + (item.profitPercentage / 100)));
      }
      totalProfitPercentage = initialValue > 0 ? (totalProfit / initialValue) * 100 : 0;
      isPositive = totalProfitPercentage >= 0;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(currentIndex: 3),
      appBar: AppBar(
        title: const Text('Portofolio'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: financeData.isLoadingInvestment && allInvestments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await financeData.fetchPortfolio();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Chart Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Portofolio', style: TextStyle(color: AppTheme.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPositive ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${isPositive ? '+' : ''}${totalProfitPercentage.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isPositive ? AppTheme.success : AppTheme.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormat.convertToIdr(totalValue),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalProfit >= 0 ? '+' : ''}${CurrencyFormat.convertToIdr(totalProfit)}',
                            style: TextStyle(
                              color: isPositive ? AppTheme.success : AppTheme.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Bar Chart (Custom Row of Bars like HomeScreen)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(15, (index) {
                              double height = 30.0 + (index * 5) + (index % 4 * 10);
                              if (height > 120) height = 120;
                              return Container(
                                width: 15,
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
                          ),
                          const SizedBox(height: 24),
                          
                          // Add Button below chart
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const AddInvestmentModal(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Tambah Data Portofolio', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildFilterTab('Semua'),
                          const SizedBox(width: 12),
                          _buildFilterTab('Crypto'),
                          const SizedBox(width: 12),
                          _buildFilterTab('Saham'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Assets List
                    filteredInvestments.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                'Belum ada portofolio investasi.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredInvestments.length,
                            itemBuilder: (context, index) {
                              final item = filteredInvestments[index];
                              return _buildAssetCard(item);
                            },
                          ),
                    const SizedBox(height: 80), // Padding for FAB/bottom
                  ],
                ),
              ),
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

  Widget _buildFilterTab(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(Investment item) {
    bool isPositive = item.profitPercentage >= 0;
    double profitAmount = 0;
    if (item.profitPercentage != -100) {
      profitAmount = item.amount - (item.amount / (1 + (item.profitPercentage / 100)));
    } else {
      profitAmount = -item.amount;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.platform, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, color: AppTheme.success, size: 8),
                        const SizedBox(width: 4),
                        const Text('LIVE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.name, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${CurrencyFormat.convertToIdr(profitAmount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? AppTheme.success : AppTheme.danger, fontSize: 14),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${item.profitPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(color: isPositive ? AppTheme.success : AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 22),
                onPressed: () => _confirmDeleteInvestment(item),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          
          // Details Rows
          _buildDetailRow('Holdings', '${item.holdings} ${item.symbol}'),
          const SizedBox(height: 12),
          _buildDetailRow('Value', CurrencyFormat.convertToIdr(item.amount)),
          const SizedBox(height: 12),
          _buildDetailRow('Avg Cost', CurrencyFormat.convertToIdr(item.avgCost)),
          const SizedBox(height: 12),
          _buildDetailRow('Current', CurrencyFormat.convertToIdr(item.currentPrice), isPrice: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
            if (isPrice) ...[
              const SizedBox(width: 4),
              const Icon(Icons.trending_up, color: AppTheme.success, size: 16),
            ]
          ],
        ),
      ],
    );
  }
}
