import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_finance/screens/main/main_screen.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onNavigate;
  final int currentIndex;

  const AppDrawer({
    super.key,
    this.onNavigate,
    this.currentIndex = 0,
  });

  void _goToPage(BuildContext context, int index) {
    Navigator.pop(context);

    if (onNavigate != null) {
      onNavigate!(index);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(
          initialIndex: index,
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeData = context.watch<FinanceProvider>();
    final authData = context.watch<AuthProvider>();
    final user = authData.currentUser;

    final userName = user?.name ?? 'Orcas';
    final userInitial = userName.isNotEmpty
        ? userName.substring(0, 1).toUpperCase()
        : 'O';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
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
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          CurrencyFormat.convertToIdr(
                            financeData.totalSaldo,
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
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
                    Icons.savings_outlined,
                    'Target Tabungan',
                    index: 3,
                  ),

                  _buildDrawerItem(
                    context,
                    Icons.trending_up,
                    'Investasi',
                    index: 4,
                  ),

                  _buildDrawerItem(
                    context,
                    Icons.credit_card,
                    'Hutang',
                    index: 5,
                  ),

                  _buildDrawerItem(
                    context,
                    Icons.repeat,
                    'Recurring',
                    index: 6,
                  ),

                  _buildDrawerItem(
                    context,
                    Icons.receipt_long,
                    'Bill',
                    index: 7,
                  ),

                  _buildDrawerItem(
                    context,
                    Icons.chat_bubble_outline,
                    'AI Chatbot',
                    index: 8,
                  ),

                  _buildDrawerItem(
                    context,
                    Icons.settings_outlined,
                    'Pengaturan',
                    index: 9,
                  ),

                  _buildDrawerItem(
                    context,
                    Icons.notifications_none,
                    'Notifikasi',
                    index: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context,
      IconData icon,
      String title, {
        required int index,
      }) {
    final bool isSelected = index == currentIndex;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          _goToPage(context, index);
        },
      ),
    );
  }
}