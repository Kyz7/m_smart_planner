import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');
    
    if (token != null && userJson != null) {
      _isAuthenticated = true;
      _user = Map<String, dynamic>.from(
        Map<String, dynamic>.from(
          Map<String, dynamic>.from({'token': token})
        )
      );
      notifyListeners();
    }
  }

  // Changed parameter name from 'email' to 'username'
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Pass username instead of email to the API service
      final response = await ApiService.login(username, password);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      await prefs.setString('user', response['user'].toString());
      
      _isAuthenticated = true;
      _user = response['user'];
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<bool> register(Map<String, String> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(userData);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      await prefs.setString('user', response['user'].toString());
      
      _isAuthenticated = true;
      _user = response['user'];
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}