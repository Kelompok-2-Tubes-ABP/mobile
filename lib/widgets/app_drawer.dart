import 'package:flutter/material.dart';
import 'package:mobile_finance/screens/budget/budget_screen.dart';
import 'package:mobile_finance/screens/main/main_screen.dart';
import 'package:mobile_finance/screens/transaction/transaction_screen.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/chatbot/chatbot.dart';
import '../screens/investment/investment_screen.dart';
import '../screens/settings/settings.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onNavigate;
  final int currentIndex;

  const AppDrawer({
    super.key,
    this.onNavigate,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final authData = context.watch<AuthProvider>();
    final user = authData.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FinanceApp',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    color:
                    AppTheme.primaryColor,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.pop(context),
                ),
              ],
            ),
          ),

          // USER CARD
          Container(
            margin:
            const EdgeInsets.symmetric(
                horizontal: 16),
            padding:
            const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight
                  .withOpacity(0.1),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                  AppTheme.primaryColor,
                  child: Text(
                    user?.name
                        .substring(0, 1)
                        .toUpperCase() ??
                        'O',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Orcas',
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormat
                          .convertToIdr(
                        financeData.totalSaldo,
                      ),
                      style: TextStyle(
                        color:
                        Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // MENUS
          _buildDrawerItem(
            context,
            Icons.dashboard_customize,
            'Dashboard',
            index: 0,
          ),
          _buildDrawerItem(
            context,
            Icons.account_balance_wallet_outlined,
            'Transaksi',
            index: 1,
          ),
          _buildDrawerItem(
            context,
            Icons.show_chart,
            'Budget',
            index: 2,
          ),
          _buildDrawerItem(
            context,
            Icons.trending_up,
            'Investasi',
            index: 3,
          ),
          _buildDrawerItem(
            context,
            Icons.chat_bubble_outline,
            'AI Chatbot',
            index: 4,
          ),
          _buildDrawerItem(
            context,
            Icons.settings_outlined,
            'Pengaturan',
            index: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context,
      IconData icon,
      String title, {
        required int index,
      }) {
    bool isSelected = index == currentIndex;

    return Container(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor
            : Colors.transparent,
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Colors.white
              : AppTheme.textPrimary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : AppTheme.textPrimary,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);

          switch (index) {
          // Dashboard / Transaksi / Budget / Investasi
            case 0: Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const MainScreen(),
              ),
            );

            case 1:Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const TransactionScreen(),
              ),
            );
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const BudgetScreen(),
                ),
              );
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const InvestmentScreen(),
                ),
              );

          // Chatbot
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const Chatbot(),
                ),
              );
              break;

          // Settings
            case 5:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const Settings(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}