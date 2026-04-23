// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/settings_provider.dart';
import '../admin/admin_home_screen.dart';
import '../employee/employee_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool  _obscure      = true;
  String? _error;
  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _error = null);
    final auth  = context.read<AuthService>();
    final error = await auth.login(
        _emailCtrl.text.trim(), _passCtrl.text.trim());
    if (error != null) {
      setState(() => _error = error);
    } else if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            auth.isAdmin ? const AdminHomeScreen() : const EmployeeHomeScreen(),
      ));
    }
  }

  void _quickLogin(String email, String pass) {
    _emailCtrl.text = email;
    _passCtrl.text  = pass;
    _login();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth     = context.watch<AuthService>();
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0D1B2A), const Color(0xFF1B3A5C)]
                : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Logo
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_rounded,
                        size: 54, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(settings.t('app_title'),
                      style: const TextStyle(fontSize: 26,
                          fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Gestion de présence intelligente',
                      style: TextStyle(fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 32),

                  // Formulaire
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(settings.t('login'),
                            style: TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E3A8A))),
                        const SizedBox(height: 20),

                        // Email
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: settings.t('email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Mot de passe
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: settings.t('password'),
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _login,
                            child: auth.isLoading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(settings.t('login'),
                                    style: const TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Comptes démo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      const Text('🔑 Comptes de démonstration',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _demoBtn('👨‍💼 Admin',
                            () => _quickLogin('admin@company.com', 'admin123'))),
                        const SizedBox(width: 8),
                        Expanded(child: _demoBtn('👤 Employé',
                            () => _quickLogin('ahmed@company.com', 'emp123'))),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Langues
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _langBtn(settings, 'fr', '🇫🇷 FR'),
                    const SizedBox(width: 8),
                    _langBtn(settings, 'en', '🇬🇧 EN'),
                    const SizedBox(width: 8),
                    _langBtn(settings, 'ar', '🇹🇳 AR'),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoBtn(String label, VoidCallback onTap) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
      child: Text(label, style: const TextStyle(fontSize: 13)));

  Widget _langBtn(SettingsProvider s, String lang, String label) {
    final sel = s.language == lang;
    return GestureDetector(
      onTap: () => s.setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? const Color(0xFF1E3A8A) : Colors.white,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}
