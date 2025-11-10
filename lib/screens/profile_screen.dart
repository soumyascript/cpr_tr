import 'package:flutter/material.dart';
import '../session_manager.dart';

class ProfileScreen extends StatefulWidget {
  static const route = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _user;
  String? _pass;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (u, p) = await SessionManager.getCredentials();
    if (!mounted) return;
    setState(() {
      _user = u;
      _pass = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stored Credentials (Demo Only)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _Item(label: 'User ID', value: _user ?? '—'),
            const SizedBox(height: 8),
            _Item(label: 'Password', value: _pass ?? '—'),
            const SizedBox(height: 24),
            const Text(
              'Note: Saved in SharedPreferences (plain text) for demo purposes.\nDo NOT do this in production.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String value;
  const _Item({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value),
          ),
        ),
      ],
    );
  }
}
