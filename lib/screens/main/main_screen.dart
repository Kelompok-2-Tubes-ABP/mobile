import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../providers/notification_provider.dart';

import '../home/home_screen.dart';
import '../transaction/transaction_screen.dart';
import '../budget/budget_screen.dart';
import '../goal/goal_screen.dart';
import '../investment/investment_screen.dart';
import '../hutang/hutang_screen.dart';
import '../recurring/recurring_screen.dart';
import '../bill/bill_screen.dart';
import '../chatbot/chatbot.dart';
import '../settings/settings.dart';
import '../profile/profile_page.dart';
import '../notifications/notif.dart';

import '../../widgets/navbar_bottom.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = dashboardIndex,
  });

  static const int dashboardIndex = 0;
  static const int transactionIndex = 1;
  static const int budgetIndex = 2;
  static const int goalIndex = 3;
  static const int investmentIndex = 4;
  static const int hutangIndex = 5;
  static const int recurringIndex = 6;
  static const int billIndex = 7;
  static const int chatbotIndex = 8;
  static const int settingsIndex = 9;
  static const int profileIndex = 10;
  static const int notificationIndex = 11;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex < MainScreen.dashboardIndex ||
        widget.initialIndex > MainScreen.notificationIndex
        ? MainScreen.dashboardIndex
        : widget.initialIndex;

    final financeProvider = context.read<FinanceProvider>();

    Future.microtask(() async {
      await financeProvider.fetchTransactions();
      await financeProvider.fetchBudgets();
      await financeProvider.fetchQuickStats();
      await financeProvider.fetchSavingsGoals();
      await financeProvider.fetchSavingsGoalSummary();
      await financeProvider.fetchPortfolio();

      if (!mounted) return;

      await context
          .read<NotificationProvider>()
          .fetchNotifications(unreadOnly: true);
    });
  }

  void _onNavigate(int index) {
    if (index < MainScreen.dashboardIndex ||
        index > MainScreen.notificationIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  int _getBottomNavIndex() {
    switch (_currentIndex) {
      case MainScreen.dashboardIndex:
        return 0;

      case MainScreen.transactionIndex:
        return 1;

      case MainScreen.budgetIndex:
        return 2;

      case MainScreen.investmentIndex:
        return 3;

      case MainScreen.profileIndex:
        return 4;

      default:
        return 0;
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        _onNavigate(MainScreen.dashboardIndex);
        break;

      case 1:
        _onNavigate(MainScreen.transactionIndex);
        break;

      case 2:
        _onNavigate(MainScreen.budgetIndex);
        break;

      case 3:
        _onNavigate(MainScreen.investmentIndex);
        break;

      case 4:
        _onNavigate(MainScreen.profileIndex);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onNavigate), // 0 Dashboard

      TransactionScreen(onNavigate: _onNavigate), // 1 Transaksi

      BudgetScreen(onNavigate: _onNavigate), // 2 Budget

      GoalScreen(onNavigate: _onNavigate), // 3 Target Tabungan

      InvestmentScreen(onNavigate: _onNavigate), // 4 Investasi

      HutangScreen(onNavigate: _onNavigate), // 5 Hutang

      RecurringScreen(onNavigate: _onNavigate), // 6 Recurring

      BillScreen(onNavigate: _onNavigate), // 7 Bill

      const Chatbot(), // 8 AI Chatbot

      Settings(onNavigate: _onNavigate), // 9 Pengaturan

      const ProfilePage(), // 10 Profil

      NotifPage(onNavigate: _onNavigate), // 11 Notifikasi
    ];

    final bool isNotificationPage =
        _currentIndex == MainScreen.notificationIndex;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // NotifPage punya navbar sendiri.
      // Settings tidak punya navbar sendiri, jadi tetap pakai navbar dari MainScreen.
      bottomNavigationBar: isNotificationPage
          ? null
          : CustomBottomNavbar(
        currentIndex: _getBottomNavIndex(),
        onTap: _onBottomNavTap,
      ),
    );
  }
}