// lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  Employee? _currentUser;
  bool _isLoading = false;

  Employee? get currentUser => _currentUser;
  bool get isLoading       => _isLoading;
  bool get isLoggedIn      => _currentUser != null;
  bool get isAdmin         => _currentUser?.role == 'admin';

  final _db = DatabaseService();

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final employees = await _db.getAllEmployees();
      final emp = employees.firstWhere(
        (e) => e.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Email introuvable'),
      );
      final expected = emp.role == 'admin' ? 'admin123' : 'emp123';
      if (password != expected) return 'Mot de passe incorrect';

      _currentUser = emp;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_user_id', emp.id);
      return null; // succès
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = prefs.getString('logged_user_id');
    if (userId != null) {
      _currentUser = await _db.getEmployeeById(userId);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_user_id');
    _currentUser = null;
    notifyListeners();
  }
}
