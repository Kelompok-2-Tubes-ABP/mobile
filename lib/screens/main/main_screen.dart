import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/notification_provider.dart';

import '../home/home_screen.dart';
import '../transaction/transaction_screen.dart';
import '../budget/budget_screen.dart';
import '../investment/investment_screen.dart';
import '../profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final financeProvider = context.read<FinanceProvider>();
    Future.microtask(() async {
      await financeProvider.fetchTransactions();
      await financeProvider.fetchBudgets();
      await financeProvider.fetchQuickStats();
      await financeProvider.fetchSavingsGoals();
      await financeProvider.fetchSavingsGoalSummary();
      await financeProvider.fetchPortfolio();
      context.read<NotificationProvider>().fetchNotifications(unreadOnly: true);
    });
  }

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onNavigate),
      const TransactionScreen(),
      const BudgetScreen(),
      const InvestmentScreen(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Investasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
