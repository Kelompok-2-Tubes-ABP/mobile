import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().getProfile();
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authData = context.watch<AuthProvider>();
    final financeData = context.watch<FinanceProvider>();
    final user = authData.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ================= PROFILE CARD =================
                    _buildProfileCard(user),

                    const SizedBox(height: 20),

                    // ================= STATS =================
                    _buildStatCard(
                      icon: Icons.calendar_today_outlined,
                      iconColor: const Color(0xff4F46E5),
                      title: 'Member Sejak',
                      value: 'Juni 2026',
                    ),
                    const SizedBox(height: 16),

                    _buildStatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xff10B981),
                      title: 'Total Transaksi',
                      value: financeData.transactions.length.toString(),
                    ),
                    const SizedBox(height: 16),

                    _buildStatCard(
                      icon: Icons.credit_card_outlined,
                      iconColor: const Color(0xffF59E0B),
                      title: 'Akun Terhubung',
                      value: '1',
                    ),

                    const SizedBox(height: 20),

                    // ================= INFORMASI PRIBADI =================
                    _buildSectionCard(
                      title: 'Informasi Pribadi',
                      child: Column(
                        children: [
                          _buildTextField('Username', user?.name ?? '-'),
                          _buildTextField('Email', user?.email ?? '-'),
                          _buildTextField('Nama Lengkap', user?.name ?? '-'),
                          _buildTextField('Nomor Telepon', '-'),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff4F46E5),
                                elevation: 4,
                                shadowColor: Colors.black26,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fitur ubah profil belum diimplementasikan')),
                                );
                              },
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= GANTI PASSWORD =================
                    _buildSectionCard(
                      title: 'Ganti Password',
                      child: Column(
                        children: [
                          _buildPasswordField('Password Lama'),
                          _buildPasswordField('Password Baru'),
                          _buildPasswordField('Konfirmasi Password Baru'),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff10B981),
                                elevation: 4,
                                shadowColor: Colors.black26,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fitur ganti password belum diimplementasikan')),
                                );
                              },
                              child: const Text(
                                'Ganti Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= ZONA BAHAYA =================
                    _buildSectionCard(
                      title: 'Zona Bahaya',
                      titleColor: const Color(0xffEF4444),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hapus akun akan menghapus semua data kamu secara permanen. Aksi ini tidak dapat dibatalkan.',
                            style: TextStyle(
                              color: Color(0xff64748B),
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffEF4444),
                              elevation: 4,
                              shadowColor: Colors.black26,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur hapus akun belum diimplementasikan')),
                              );
                            },
                            child: const Text(
                              'Hapus Akun',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ================= PROFILE CARD =================
  Widget _buildProfileCard(User? user) {
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? 'guest@financeapp.com';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'G';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xff4F46E5),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xff10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E293B),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            email,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff4F46E5),
              side: const BorderSide(color: Color(0xff4F46E5)),
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {},
            child: const Text('Edit Profil'),
          ),
        ],
      ),
    );
  }

  // ================= STATS CARD =================
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SECTION CARD =================
  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Color titleColor = const Color(0xff1E293B),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _buildTextField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff1E293B),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value),
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff1E293B),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}