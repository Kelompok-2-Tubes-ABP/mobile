import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final String _baseUrl = 'http://172.24.217.180:8000';

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isFetchingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      if (!mounted) return;

      setState(() {
        _isFetchingHistory = false;
      });
      return;
    }

    try {
      final url = Uri.parse('$_baseUrl/chatbot/history');

      print('CHAT HISTORY URL: $url');
      print('CHAT HISTORY TOKEN: $token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('CHAT HISTORY STATUS: ${response.statusCode}');
      print('CHAT HISTORY BODY: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = data['messages'] as List<dynamic>? ?? [];

        setState(() {
          _messages = history.map((e) {
            final messageType = e['message_type']?.toString() ?? 'user';

            return {
              'role': messageType,
              'content': messageType == 'assistant'
                  ? e['response']?.toString() ?? ''
                  : e['message']?.toString() ?? '',
              'timestamp': e['timestamp']?.toString() ?? '',
            };
          }).toList();

          _isFetchingHistory = false;
        });

        _scrollToBottom();
      } else {
        setState(() {
          _isFetchingHistory = false;
        });
      }
    } catch (e) {
      print('FETCH CHAT HISTORY ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isFetchingHistory = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    try {
      final url = Uri.parse('$_baseUrl/chatbot/clear');

      print('CLEAR CHAT URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('CLEAR CHAT STATUS: ${response.statusCode}');
      print('CLEAR CHAT RESPONSE: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _messages.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History chat berhasil dihapus'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus history chat'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus history: $e'),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final message = text ?? _messageController.text.trim();

    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final token = await _storage.read(key: 'token');

    if (token == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    try {
      final url = Uri.parse('$_baseUrl/chatbot/message');

      final requestBody = jsonEncode({
        'message': message,
      });

      print('SEND MESSAGE URL: $url');
      print('SEND MESSAGE BODY: $requestBody');
      print('SEND MESSAGE TOKEN: $token');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('SEND MESSAGE STATUS: ${response.statusCode}');
      print('SEND MESSAGE RESPONSE: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': data['response']?.toString() ?? '',
            'timestamp':
            data['timestamp']?.toString().isNotEmpty == true
                ? data['timestamp'].toString()
                : DateTime.now().toIso8601String(),
          });
          _isLoading = false;
        });

        _scrollToBottom();
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim pesan'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      // Tidak ada bottomNavigationBar di sini.
      // Bottom navbar cukup dari MainScreen / CustomBottomNavbar.

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Finance Advisor 🤖',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Powered by Gemma3 AI',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearHistory,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // MAIN CHAT CARD
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: _isFetchingHistory
                            ? const Center(
                          child: CircularProgressIndicator(),
                        )
                            : _messages.isEmpty
                            ? _buildEmptyState()
                            : _buildChatList(),
                      ),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),

                      const Divider(
                        color: Color(0xffE2E8F0),
                        height: 1,
                      ),

                      // INPUT
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'Tanya tentang keuanganmu...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xff94A3B8),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xffE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xffE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xff4F46E5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _isLoading ? null : () => _sendMessage(),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? Colors.grey
                                      : const Color(0xffA78BFA),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.send_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coba tanya:',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 16),

          _chip('📊 Analisis pengeluaran bulan ini'),
          _chip('💡 Tips hemat untuk kategori makanan'),
          _chip('📈 Rekomendasikan strategi investasi'),
          _chip('🎯 Evaluasi progress tabungan saya'),
          _chip('⚠️ Tagihan apa yang harus dibayar minggu ini?'),
          _chip('💰 Berapa sisa budget saya?'),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xffF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Halo! Saya siap bantu analisis keuangan kamu 🤖\n\n'
                  'Saya bisa membantu:\n'
                  '• Analisis pengeluaran\n'
                  '• Tips hemat & investasi\n'
                  '• Evaluasi progress tabungan\n'
                  '• Rekomendasi budget\n\n'
                  'Ada yang ingin kamu tanyakan?',
              style: TextStyle(
                height: 1.45,
                fontSize: 16,
                color: Color(0xff1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xff4F46E5)
                  : const Color(0xffF1F5F9),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
                bottomLeft: !isUser
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Text(
              msg['content']?.toString() ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xff1E293B),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String text) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _sendMessage(text),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffEEF2FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff4F46E5),
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}