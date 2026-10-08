import 'package:flutter/material.dart';
import '../core/utils/error_utils.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/socket/socket_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _tokenStorage.init();
    if (_tokenStorage.isAuthenticated) {
      try {
        _currentUser = await _authService.getMe();
        _status = AuthStatus.authenticated;
        SocketService().connect(force: true);
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        await _tokenStorage.clear();
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Doctor Login with Email & Password: POST /auth/login
  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        email: email.trim(),
        password: password,
      );
      _status = AuthStatus.authenticated;
      SocketService().connect(force: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Send OTP: POST /auth/send-otp
  Future<bool> sendOtp(String phone) async {
    _errorMessage = null;
    try {
      await _authService.sendOtp(phone.trim());
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and log in: POST /auth/verify-otp
  Future<bool> verifyOtp({required String phone, required String otp}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.verifyOtp(
        phone: phone.trim(),
        otp: otp.trim(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Login with Phone and PIN: POST /auth/login-pin
  Future<bool> loginWithPin({required String phone, required String pin}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.loginWithPin(
        phone: phone.trim(),
        pin: pin.trim(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Request 6-digit password reset OTP: POST /auth/forgot-password
  Future<bool> forgotPassword(String email) async {
    _errorMessage = null;
    try {
      await _authService.forgotPassword(email.trim());
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Reset password: POST /auth/reset-password
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _errorMessage = null;
    try {
      await _authService.resetPassword(
        email: email.trim(),
        otp: otp.trim(),
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
