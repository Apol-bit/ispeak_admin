import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/validator_layout.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iSpeak Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        fontFamily: AppTheme.fontFamily, 
      ),
      home: const AuthGate(),
    );
  }
}

/// Checks for saved session on startup.
/// If a valid session exists, routes directly to the correct layout.
/// Otherwise, shows the login screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await AuthService.getSession();

    if (!mounted) return;

    if (session != null) {
      final role = session['userRole'] ?? 'user';
      final name = session['userName'] ?? 'User';
      final email = session['userEmail'] ?? '';

      Widget destination;
      if (role == 'admin') {
        destination = MainLayout(adminName: name, adminEmail: email);
      } else if (role == 'validator') {
        destination = ValidatorLayout(validatorName: name, validatorEmail: email);
      } else {
        // Role not admin/validator — clear invalid session and show login
        await AuthService.clearSession();
        setState(() => _isLoading = false);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Brief splash while checking saved session
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ispeak_logo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const LoginScreen();
  }
}