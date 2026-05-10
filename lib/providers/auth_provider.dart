import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;

  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    // Mock login delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Accept any credentials for demo purposes
    if (email.isNotEmpty && password.isNotEmpty) {
      _currentUser = User(
        id: 'u1',
        name: 'Orcas',
        email: email,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    notifyListeners();
  }
}
