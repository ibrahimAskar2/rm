import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String photoUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl = '',
  });
}

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    // محاكاة عملية تسجيل الدخول
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _user = User(
      id: '1',
      name: 'مستخدم تجريبي',
      email: email,
      role: 'مدير',
      photoUrl: '',
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _user = null;
    _isLoading = false;
    notifyListeners();
  }
}
