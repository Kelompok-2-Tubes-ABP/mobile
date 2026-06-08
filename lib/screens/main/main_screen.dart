import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../transaction/transaction_screen.dart';
import '../budget/budget_screen.dart';
import '../investment/investment_screen.dart';
import '../profile/profile_page.dart';
import '../../widgets/navbar_bottom.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavigate,
      ),
    );
  }
}