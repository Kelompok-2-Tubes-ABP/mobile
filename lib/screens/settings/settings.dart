import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/onboarding_screen.dart';

class Settings extends StatelessWidget {
  final Function(int)? onNavigate;

  const Settings({
    super.key,
    this.onNavigate,
  });

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

      // Bottom navbar dan floatingActionButton dihapus dari sini.
      // Bottom navbar sudah disediakan oleh MainScreen.

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ),
              const SizedBox(height: 24),
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

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffEF4444),
                    minimumSize: const Size(
                      double.infinity,
                      56,
                    ),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: title == 'Hapus Akun'
                        ? Colors.red
                        : const Color(0xff1E293B),
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
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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