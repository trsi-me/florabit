import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../session_store.dart';
import '../user_provider.dart';
import 'login_screen.dart';
import '../main_shell.dart';

/// يقرر عند الإقلاع: استعادة جلسة محفوظة أو شاشة تسجيل الدخول.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final session = await SessionStore.load();
    if (session != null) {
      UserProvider.setUser(session);
      if (mounted) {
        setState(() {
          _hasSession = true;
          _loading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'فلورابيت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_hasSession) return const MainShell();
    return const LoginScreen();
  }
}
