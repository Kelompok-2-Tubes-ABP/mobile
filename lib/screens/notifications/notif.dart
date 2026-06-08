import 'package:flutter/material.dart';
import 'package:mobile_finance/widgets/navbar_bottom.dart';
import 'package:mobile_finance/widgets/app_drawer.dart';

import 'package:mobile_finance/screens/main/main_screen.dart';
import 'package:mobile_finance/screens/transaction/transaction_screen.dart';
import 'package:mobile_finance/screens/budget/budget_screen.dart';
import 'package:mobile_finance/screens/investment/investment_screen.dart';
import 'package:mobile_finance/screens/profile/profile_page.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({super.key});

  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int currentIndex = 0;

  // ===========================
  // BOTTOM NAVIGATION SWITCH
  // ===========================
  void _onBottomTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TransactionScreen(),
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BudgetScreen(),
          ),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const InvestmentScreen(),
          ),
        );
        break;

      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xffF5F6FA),

      drawer: const AppDrawer(),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff5B5BFF),
        elevation: 5,
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),

      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 0,
        onTap: _onBottomTap,
      ),

      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _headerSection(),
                    const SizedBox(height: 28),

                    _sectionTitle("Hari Ini"),
                    const SizedBox(height: 14),

                    _notificationCard(
                      title: "Budget terlampaui",
                      subtitle: "Budget Makanan 100%\nterlampaui!",
                      time: "14:30",
                      icon: Icons.error_outline,
                      iconColor: Colors.red,
                      isNew: true,
                      bordered: true,
                    ),

                    _notificationCard(
                      title: "Budget hampir habis",
                      subtitle: "Budget Transportasi 80%\nterpakai",
                      time: "10:15",
                      icon: Icons.info_outline,
                      iconColor: Colors.deepOrange,
                      isNew: true,
                      bordered: true,
                    ),

                    _notificationCard(
                      title: "Tagihan jatuh tempo",
                      subtitle: "PLN jatuh tempo besok, Rp\n350.000",
                      time: "08:00",
                      icon: Icons.attach_money,
                      iconColor: Colors.orange,
                      isNew: true,
                      bordered: true,
                    ),

                    const SizedBox(height: 20),
                    _sectionTitle("Kemarin"),
                    const SizedBox(height: 14),

                    _notificationCard(
                      title: "Goal milestone",
                      subtitle: "Tabungan Laptop 50% tercapai! 🎉",
                      time: "2 Mei, 16:45",
                      icon: Icons.gps_fixed,
                      iconColor: Colors.green,
                    ),

                    _notificationCard(
                      title: "Recurring executed",
                      subtitle: "Langganan Netflix Rp 54.000 dicatat",
                      time: "2 Mei, 12:00",
                      icon: Icons.sync_alt,
                      iconColor: Colors.indigo,
                    ),

                    _notificationCard(
                      title: "New insight",
                      subtitle: "AI menemukan pola baru di\npengeluaran kamu",
                      time: "2 Mei, 09:30",
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.amber,
                    ),

                    const SizedBox(height: 20),
                    _sectionTitle("Minggu Ini"),
                    const SizedBox(height: 14),

                    _notificationCard(
                      title: "Debt reminder",
                      subtitle: "Hutang ke Andi jatuh tempo 3\nhari lagi",
                      time: "1 Mei, 10:00",
                      icon: Icons.attach_money,
                      iconColor: Colors.red,
                    ),

                    _notificationCard(
                      title: "Achievement unlocked",
                      subtitle: "Kamu sudah menabung 5 kali\nminggu ini! 🏆",
                      time: "30 Apr, 18:20",
                      icon: Icons.trending_up,
                      iconColor: Colors.green,
                    ),

                    _notificationCard(
                      title: "Bill paid",
                      subtitle:
                      "Pembayaran Internet Rp 350.000\nberhasil dicatat",
                      time: "29 Apr, 14:10",
                      icon: Icons.attach_money,
                      iconColor: Colors.orange,
                    ),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xffEAECEF)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            icon: const Icon(Icons.menu),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff27364A),
                ),
              ),
            ),
          ),
          Stack(
            children: [
              const Icon(Icons.notifications_none, size: 30),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notifikasi",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff27364A),
                ),
              ),
              SizedBox(height: 6),
              Text(
                "3 notifikasi belum\ndibaca",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff7A869A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xff5B5BFF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "Tandai Semua Dibaca",
            style: TextStyle(
              color: Color(0xff5B5BFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        color: Color(0xff7A869A),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _notificationCard({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color iconColor,
    bool isNew = false,
    bool bordered = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
        bordered ? Border.all(color: const Color(0xff5B5BFF)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xffF2F3F7),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff2D3A4D),
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffECEBFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Baru",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff5B5BFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xff6D7890),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff7A869A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}