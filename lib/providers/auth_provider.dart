import 'package:flutter/material.dart';
import '../models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;

  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;

  final storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('http://localhost:8000/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await storage.write(key: 'token', value: data['token']);

        await storage.write(
          key: 'expires_at',
          value: DateTime.now()
              .add(Duration(seconds: data['expires_in']))
              .toIso8601String(),
        );

        print('TOKEN BERHASIL DISIMPAN');

        notifyListeners();
        return true;
      }

      print('Login gagal: ${response.body}');
      return false;
    } catch (e) {
      print('Error login: $e');
      return false;
    }
  }

  Future<void> getProfile() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    print('TOKEN: $token');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('PROFILE STATUS: ${response.statusCode}');
      final data = jsonDecode(response.body);

      _currentUser = User(
        name: data['Message']['username'],
        email: data['Message']['email'],
      );

      notifyListeners();

      print('USER BERHASIL DIMUAT');
    } catch (e) {
      print('Error profile: $e');
    }
  }

  Future<void> getTransactions() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      print('TOKEN TIDAK DITEMUKAN');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/transaction/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('TRANSACTION STATUS: ${response.statusCode}');
      print('TRANSACTION BODY: ${response.body}');
    } catch (e) {
      print('Error transaction: $e');
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'expires_at');

    _currentUser = null;
    notifyListeners();
  }

  Future<bool> register(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) async {
    if (password != confirmPassword) {
      print('Password tidak sama');
      return false;
    }

    final url = Uri.parse('http://localhost:8000/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print('REGISTER STATUS: ${response.statusCode}');
      print('REGISTER BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error register: $e');
      return false;
    }
  }
}
