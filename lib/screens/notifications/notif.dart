import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_finance/widgets/navbar_bottom.dart';

import 'package:mobile_finance/screens/main/main_screen.dart';
import 'package:mobile_finance/providers/notification_provider.dart';
import 'package:mobile_finance/models/notification.dart';

class NotifPage extends StatefulWidget {
  final Function(int)? onNavigate;

  const NotifPage({
    super.key,
    this.onNavigate,
  });

  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _goToMainIndex(int mainIndex) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(mainIndex);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(
          initialIndex: mainIndex,
        ),
      ),
          (route) => false,
    );
  }

  void _onBottomTap(int index) {
    switch (index) {
      case 0:
        _goToMainIndex(MainScreen.dashboardIndex);
        break;

      case 1:
        _goToMainIndex(MainScreen.transactionIndex);
        break;

      case 2:
        _goToMainIndex(MainScreen.budgetIndex);
        break;

      case 3:
        _goToMainIndex(MainScreen.investmentIndex);
        break;

      case 4:
        _goToMainIndex(MainScreen.profileIndex);
        break;
    }
  }

  Future<void> _refresh() async {
    await context.read<NotificationProvider>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 0,
        onTap: _onBottomTap,
      ),

      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: notifProvider.isLoading
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : notifProvider.notifications.isEmpty
                    ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Text(
                        "Tidak ada notifikasi",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                )
                    : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 20),
                    _headerSection(notifProvider),
                    const SizedBox(height: 28),
                    ...notifProvider.notifications
                        .map(
                          (notif) => _notificationCard(notif),
                    )
                        .toList(),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xffEAECEF),
          ),
        ),
      ),
      child: const Center(
        child: Text(
          "Notifications",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xff27364A),
          ),
        ),
      ),
    );
  }

  Widget _headerSection(NotificationProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Notifikasi",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff27364A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${provider.unreadCount} notifikasi belum\ndibaca",
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xff7A869A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => provider.markAllAsRead(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xff5B5BFF),
              ),
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
        ),
      ],
    );
  }

  Widget _notificationCard(UserNotification notif) {
    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          context.read<NotificationProvider>().markAsRead(notif.id);
        }

        print("NOTIF CLICKED: ${notif.id}");
        print("NOTIF TYPE: ${notif.type}");

        if (notif.type == 'budget') {
          print("ROUTE TARGET: BudgetScreen");
          _goToMainIndex(MainScreen.budgetIndex);
        } else if (notif.type == 'transaction') {
          print("ROUTE TARGET: TransactionScreen");
          _goToMainIndex(MainScreen.transactionIndex);
        } else if (notif.type == 'investment' || notif.type == 'goal') {
          print("ROUTE TARGET: InvestmentScreen");
          _goToMainIndex(MainScreen.investmentIndex);
        } else {
          print("ROUTE TARGET: Dialog");

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    notif.icon,
                    color: notif.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(notif.title),
                  ),
                ],
              ),
              content: Text(notif.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xffF0F4FF),
          borderRadius: BorderRadius.circular(22),
          border: !notif.isRead
              ? Border.all(
            color: const Color(0xff5B5BFF).withOpacity(0.5),
          )
              : null,
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
              child: Icon(
                notif.icon,
                color: notif.color,
              ),
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
                          notif.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff2D3A4D),
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
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
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xff6D7890),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${notif.createdAt.day}/${notif.createdAt.month} ${notif.createdAt.hour.toString().padLeft(2, '0')}:${notif.createdAt.minute.toString().padLeft(2, '0')}",
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
      ),
    );
  }
}