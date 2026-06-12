import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/navbar_bottom.dart';
import '../../providers/auth_provider.dart';
import '../main/main_screen.dart';
import '../transaction/transaction_screen.dart';
import '../budget/budget_screen.dart';
import '../investment/investment_screen.dart';
import '../profile/profile_page.dart';
import '../auth/onboarding_screen.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  void _navigateBottomBar(BuildContext context, int index) {
    Widget page;

    switch (index) {
      case 0:
        page = const MainScreen();
        break;
      case 1:
        page = const TransactionScreen();
        break;
      case 2:
        page = const BudgetScreen();
        break;
      case 3:
        page = const InvestmentScreen();
        break;
      case 4:
        page = const ProfilePage();
        break;
      default:
        page = const MainScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 4,
        onTap: (index) => _navigateBottomBar(context, index),
      ),

      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color(0xff4F46E5),
              Color(0xff6366F1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E293B),
                ),
              ),

              const SizedBox(height: 24),

              // ================= AKUN =================
              _buildCard(
                title: 'Akun',
                children: [
                  _buildItem(
                    Icons.shield_outlined,
                    'Edit Profil',
                    'Ubah informasi pribadi kamu',
                    color: const Color(0xff4F46E5),
                  ),
                  _buildItem(
                    Icons.shield_outlined,
                    'Ganti Password',
                    'Perbarui password akun kamu',
                    color: const Color(0xff4F46E5),
                  ),
                  _buildItem(
                    Icons.shield_outlined,
                    'Hapus Akun',
                    'Hapus akun dan semua data',
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= PREFERENSI =================
              _buildCard(
                title: 'Preferensi',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildItem(
                          Icons.wb_sunny_outlined,
                          'Dark Mode',
                          'Aktifkan tema gelap',
                          color: const Color(0xff4F46E5),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xff4F46E5),
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(12),
                          ),
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          'Aktifkan',
                          style: TextStyle(
                            color:
                            Color(0xff4F46E5),
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildItem(
                    Icons.language,
                    'Bahasa',
                    'Indonesia',
                    color: const Color(0xff4F46E5),
                  ),
                  _buildItem(
                    Icons.language,
                    'Mata Uang Utama',
                    'IDR - Rupiah',
                    color: const Color(0xff4F46E5),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= NOTIFIKASI =================
              _buildCard(
                title: 'Notifikasi',
                children: const [
                  _TextOnlyItem(
                    'Budget Warning',
                    'Notifikasi saat budget hampir habis',
                  ),
                  _TextOnlyItem(
                    'Bill Reminders',
                    'Pengingat tagihan yang akan jatuh tempo',
                  ),
                  _TextOnlyItem(
                    'Goal Alerts',
                    'Notifikasi milestone target tabungan',
                  ),
                  _TextOnlyItem(
                    'AI Insights',
                    'Notifikasi insight keuangan dari AI',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= DATA =================
              _buildCard(
                title: 'Data',
                children: [
                  _buildItem(
                    Icons.download_outlined,
                    'Export CSV',
                    'Download data transaksi',
                    color: const Color(0xff4F46E5),
                  ),
                  Opacity(
                    opacity: 0.45,
                    child: _buildItem(
                      Icons.download_outlined,
                      'Webhook Settings',
                      'Coming soon',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= TENTANG =================
              _buildCard(
                title: 'Tentang',
                children: [
                  _buildItem(
                    Icons.shield_outlined,
                    'Versi App',
                    'v1.0.0',
                    color: const Color(0xff4F46E5),
                  ),
                  _buildItem(
                    Icons.shield_outlined,
                    'Privacy Policy',
                    'Kebijakan privasi kami',
                    color: const Color(0xff4F46E5),
                  ),
                  _buildItem(
                    Icons.shield_outlined,
                    'Syarat & Ketentuan',
                    'Ketentuan penggunaan',
                    color: const Color(0xff4F46E5),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= LOGOUT =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xffEF4444),
                    minimumSize:
                    const Size(double.infinity, 56),
                    elevation: 4,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w500,
              color: Color(0xff1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildItem(
      IconData icon,
      String title,
      String subtitle, {
        required Color color,
      }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w400,
                    color: title ==
                        'Hapus Akun'
                        ? Colors.red
                        : const Color(
                        0xff1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color:
                    Color(0xff64748B),
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

class _TextOnlyItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TextOnlyItem(
      this.title,
      this.subtitle,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xff1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }
}