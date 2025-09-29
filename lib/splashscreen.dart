import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naipay/model/getusersmodels.dart';
import 'package:naipay/screens/registerscreen.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:naipay/session_provider.dart'; // Import SessionProvider

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    try {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

      // Load session from storage
      await sessionProvider.loadSession();

      final email = sessionProvider.userEmail;
      if (email == null || email.isEmpty) {
        _navigateToRegister();
        return;
      }

      // Check local session expiry (48 hours)
      final isSessionValid = await sessionProvider.isSessionValid();
      if (!isSessionValid) {
        await sessionProvider.clearSession();
        _navigateToRegister();
        return;
      }

      // Try to validate session with API
      try {
        final userInfo = await UserService()
            .getUsersInfo(Getuser(email: email))
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('API request timed out');
        });

        if (userInfo == null || userInfo['session'] == null) {
          await sessionProvider.clearSession();
          _navigateToRegister();
          return;
        }

        final session = userInfo['session'];
        final bool isActive = session['isActive'] ?? false;
        final String? expiresAt = session['expiresAt'];

        if (!isActive || expiresAt == null) {
          await sessionProvider.clearSession();
          _navigateToRegister();
          return;
        }

        final expiryDate = DateTime.tryParse(expiresAt);
        final now = DateTime.now();

        if (expiryDate != null && expiryDate.isAfter(now)) {
          _navigateToHome(email);
        } else {
          await sessionProvider.clearSession();
          _navigateToRegister();
        }
      } catch (e) {
        // Fallback to local session if API call fails (e.g., offline)
        if (isSessionValid) {
          _navigateToHome(email);
        } else {
          await sessionProvider.clearSession();
          _navigateToRegister();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error checking session: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      _navigateToRegister();
    }
  }

  void _navigateToHome(String email) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Homepage(email: email)),
      );
    }
  }

  void _navigateToRegister() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}