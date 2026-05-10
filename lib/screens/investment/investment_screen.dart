import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/finance_provider.dart';
import '../../models/investment.dart';
import '../../widgets/app_drawer.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  String selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final allInvestments = financeData.investments;

    List<Investment> filteredInvestments = allInvestments;
    if (selectedFilter != 'Semua') {
      filteredInvestments = allInvestments.where((item) => item.type.toLowerCase() == selectedFilter.toLowerCase()).toList();
    }

    double totalValue = filteredInvestments.fold(0, (sum, item) => sum + item.amount);
    
    // Mock profit calculation
    double totalProfit = 0;
    double initialValue = 0;
    for(var item in filteredInvestments) {
      double profitAmount = item.amount - (item.amount / (1 + (item.profitPercentage / 100)));
      totalProfit += profitAmount;
      initialValue += (item.amount / (1 + (item.profitPercentage / 100)));
    }
    double totalProfitPercentage = initialValue > 0 ? (totalProfit / initialValue) * 100 : 0;
    bool isPositive = totalProfitPercentage >= 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(currentIndex: 3),
      appBar: AppBar(
        title: const Text('Portofolio'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
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
                        // Modal to add investment (placeholder or implement simple one)
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur tambah investasi belum tersedia.')));
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
            ListView.builder(
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
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(item.symbol, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormat.convertToIdr(item.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? AppTheme.success : AppTheme.danger,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${item.profitPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? AppTheme.success : AppTheme.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
