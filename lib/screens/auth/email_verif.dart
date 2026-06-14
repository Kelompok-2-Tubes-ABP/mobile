import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme.dart';
import 'login_screen.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final TextEditingController otpController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;

  static const String baseUrl = 'https://backend-financeapi.up.railway.app';

  Future<void> verifyOTP() async {
    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP harus 6 digit')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify/code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': otpController.text.trim()}),
      );

      print(response.statusCode);
      print(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email berhasil diverifikasi')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        String message = 'OTP tidak valid';

        try {
          final data = jsonDecode(response.body);

          message = data['error'] ?? data['message'] ?? message;
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      print(response.statusCode);
      print(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP berhasil dikirim ulang')),
        );
      } else {
        String message = 'Gagal mengirim ulang OTP';

        try {
          final data = jsonDecode(response.body);

          message = data['error'] ?? data['message'] ?? message;
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Verifikasi Email',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                'Masukkan kode OTP 6 digit yang telah dikirim ke email:',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 8),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '123456',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : verifyOTP,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verifikasi'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _isResending ? null : resendOTP,
                child: _isResending
                    ? const CircularProgressIndicator()
                    : const Text('Kirim Ulang OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
