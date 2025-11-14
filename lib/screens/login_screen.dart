import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../session_manager.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _statusMessage;
  bool _statusOk = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    try {
      // REAL API CALL to your login endpoint
      final result = await AuthService.login(username, password);

      // DEBUG: Print the result structure
      print('Login Result: $result');

      if (result['success'] == true) {
        // SAFE ACCESS with null checks
        final token = result['token']?.toString();
        final user = result['user'];

        if (token == null || user == null) {
          if (!mounted) return;
          setState(() {
            _statusOk = false;
            _statusMessage = 'Invalid response from server';
          });
          return;
        }

        // Update auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.login(token, user);

        // Keep session manager for backward compatibility
        await SessionManager.saveCredentials(username, password);

        if (!mounted) return;
        setState(() {
          _statusOk = true;
          _statusMessage = 'Login successful';
        });

        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      } else {
        if (!mounted) return;
        setState(() {
          _statusOk = false;
          _statusMessage = result['message']?.toString() ?? 'Login failed';
        });
      }
    } catch (e) {
      print('Login screen error: $e');
      if (!mounted) return;
      setState(() {
        _statusOk = false;
        _statusMessage = 'Login failed: ${e.toString()}';
      });
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/images/med.png', fit: BoxFit.cover),
          // Dark overlay for contrast
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo + Title stack
                            Column(
                              children: [
                                Image.asset(
                                  'assets/images/logo_new.png',
                                  height: 72,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'CPR',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('for',
                                    style:
                                    Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                const Text(
                                  'NextGen HealthCare',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text('Training',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _userCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter username' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                      _obscure ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter password' : null,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Text('Login'),
                            ),
                            const SizedBox(height: 8),
                            if (_statusMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _statusOk ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  border: Border.all(
                                    color: _statusOk ? Colors.green : Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _statusMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _statusOk ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}