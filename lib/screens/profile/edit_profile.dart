import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "https://backend-financeapi.up.railway.app";
final storage = const FlutterSecureStorage();

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
  final String currentEmail;

  const EditProfilePage({
    super.key,
    required this.currentUsername,
    required this.currentEmail,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController usernameController;
  late TextEditingController emailController;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController(text: widget.currentUsername);

    emailController = TextEditingController(text: widget.currentEmail);
  }

  Future<void> updateProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');

      print("TOKEN = $token");

      Map<String, dynamic> body = {};

      body["username"] = usernameController.text.trim();
      body["email"] = emailController.text.trim();

      if (currentPasswordController.text.isNotEmpty &&
          newPasswordController.text.isNotEmpty) {
        body["current_password"] = currentPasswordController.text.trim();

        body["new_password"] = newPasswordController.text.trim();
      }

      final response = await http.patch(
        Uri.parse('https://backend-financeapi.up.railway.app/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile berhasil diperbarui")),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Gagal update profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),

              const Divider(),

              const SizedBox(height: 12),

              const Text(
                "Ganti Password (Opsional)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password Saat Ini",
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password Baru"),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            updateProfile();
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Simpan Perubahan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
