import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionProvider extends ChangeNotifier {
  String? _userEmail;
  final _storage = const FlutterSecureStorage();

  String? get userEmail => _userEmail;

  Future<void> loadSession() async {
    try {
      _userEmail = await _storage.read(key: 'email');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
  }

  Future<void> setUserEmail(String email) async {
    try {
      await _storage.write(key: 'email', value: email);
      await _storage.write(
          key: 'login_timestamp', value: DateTime.now().toIso8601String());
      _userEmail = email;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: 'email');
      await _storage.delete(key: 'login_timestamp');
      _userEmail = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  bool get isLoggedIn => _userEmail != null && _userEmail!.isNotEmpty;

  Future<bool> isSessionValid() async {
    try {
      final loginTimestampStr = await _storage.read(key: 'login_timestamp');
      if (loginTimestampStr == null) return false;

      final loginTime = DateTime.tryParse(loginTimestampStr);
      if (loginTime == null) return false;

      return DateTime.now().difference(loginTime) < const Duration(hours: 48);
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false;
    }
  }
}