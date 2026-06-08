import 'package:flutter/material.dart';
import '../../widgets/navbar_bottom.dart';
import '../main/main_screen.dart';
import '../transaction/transaction_screen.dart';
import '../budget/budget_screen.dart';
import '../investment/investment_screen.dart';
import '../profile/profile_page.dart';

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final TextEditingController _messageController = TextEditingController();

  void _navigateBottomBar(int index) {
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pesan terkirim: ${_messageController.text}',
        ),
      ),
    );

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      // ================= NAVBAR =================
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 0,
        onTap: _navigateBottomBar,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ================= HEADER =================
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI Finance Advisor 🤖',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Powered by Gemma3 AI • Bahasa Indonesia',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ================= MAIN CARD =================
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const Text(
                                'Coba tanya:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(
                                      0xff64748B),
                                ),
                              ),
                              const SizedBox(
                                  height: 16),

                              _chip(
                                  '📊 Analisis pengeluaran bulan ini'),
                              _chip(
                                  '💡 Tips hemat untuk kategori\nmakanan'),
                              _chip(
                                  '📈 Rekomendasikan strategi\ninvestasi'),
                              _chip(
                                  '🎯 Evaluasi progress tabungan saya'),
                              _chip(
                                  '⚠️ Tagihan apa yang harus dibayar\nminggu ini?'),
                              _chip(
                                  '💰 Berapa sisa budget saya?'),

                              const SizedBox(
                                  height: 24),

                              // ================= BOT MESSAGE =================
                              Container(
                                padding:
                                const EdgeInsets
                                    .all(18),
                                decoration:
                                BoxDecoration(
                                  color:
                                  const Color(
                                      0xffF1F5F9),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      18),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: const [
                                    Text(
                                      'Halo! Saya siap bantu analisis keuangan kamu 🤖\n\n'
                                          'Saya bisa membantu:\n'
                                          '• Analisis pengeluaran\n'
                                          '• Tips hemat & investasi\n'
                                          '• Evaluasi progress tabungan\n'
                                          '• Rekomendasi budget\n\n'
                                          'Ada yang ingin kamu tanyakan?',
                                      style:
                                      TextStyle(
                                        height:
                                        1.45,
                                        fontSize:
                                        16,
                                        color: Color(
                                            0xff1E293B),
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                        22),
                                    Text(
                                      '10:00',
                                      style:
                                      TextStyle(
                                        color: Color(
                                            0xff64748B),
                                        fontSize:
                                        13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      const Divider(
                        color: Color(0xffE2E8F0),
                      ),
                      const SizedBox(height: 14),

                      // ================= INPUT =================
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                              _messageController,
                              decoration:
                              InputDecoration(
                                hintText:
                                'Tanya tentang keuanganmu...',
                                hintStyle:
                                const TextStyle(
                                  color: Color(
                                      0xff94A3B8),
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor:
                                const Color(
                                    0xffF8FAFC),
                                contentPadding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  18,
                                  vertical:
                                  16,
                                ),
                                border:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      14),
                                  borderSide:
                                  const BorderSide(
                                    color: Color(
                                        0xffE2E8F0),
                                  ),
                                ),
                                enabledBorder:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      14),
                                  borderSide:
                                  const BorderSide(
                                    color: Color(
                                        0xffE2E8F0),
                                  ),
                                ),
                                focusedBorder:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      14),
                                  borderSide:
                                  const BorderSide(
                                    color: Color(
                                        0xff4F46E5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 68,
                              height: 58,
                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                    0xffA78BFA),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                    18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                        0.08),
                                    blurRadius:
                                    6,
                                    offset:
                                    const Offset(
                                        0, 2),
                                  ),
                                ],
                              ),
                              child:
                              const Icon(
                                Icons
                                    .send_outlined,
                                color: Colors
                                    .white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffEEF2FF),
        borderRadius:
        BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xff4F46E5),
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }
}