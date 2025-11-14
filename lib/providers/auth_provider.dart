import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isLoggedIn = await AuthService.isLoggedIn();
    if (_isLoggedIn) {
      _user = await AuthService.getUserData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String token, Map<String, dynamic> userData) async {
    await AuthService.storeAuthData(token, userData);
    _isLoggedIn = true;
    _user = userData;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.clearAuthData();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  // Method to refresh user data from /me endpoint
  Future<void> refreshUserData() async {
    final result = await AuthService.verifyToken();
    if (result['success']) {
      _user = result['user'];
      await AuthService.storeAuthData(
          await AuthService.getToken() ?? '',
          _user!
      );
      notifyListeners();
    }
  }
}