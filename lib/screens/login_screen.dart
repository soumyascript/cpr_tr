import 'package:flutter/material.dart';
import '../session_manager.dart';

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

  // Hardcoded demo credentials
  static const _dummyUser = 'demo';
  static const _dummyPass = 'demo123';

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

    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();

    await Future.delayed(const Duration(milliseconds: 200));

    if (u == _dummyUser && p == _dummyPass) {
      await SessionManager.saveCredentials(u, p);
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
        _statusMessage = 'Invalid credentials';
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
                                labelText: 'User ID',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter user id' : null,
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
                                  : const Text('Next'),
                            ),
                            const SizedBox(height: 8),
                            if (_statusMessage != null)
                              Text(
                                _statusMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _statusOk ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
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
