import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // ADD THIS

class ProfileScreen extends StatefulWidget {
  static const route = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (user != null) ...[
              _Item(label: 'User ID', value: user['Unm'] ?? '—'),
              const SizedBox(height: 8),
              _Item(label: 'Name', value: user['name'] ?? '—'),
              const SizedBox(height: 8),
              _Item(label: 'User Type', value: user['utype_id'] ?? '—'),
              const SizedBox(height: 8),
              _Item(label: 'Organization', value: user['org_id'] ?? '—'),
              const SizedBox(height: 8),
              _Item(label: 'Mobile', value: user['umob'] ?? '—'),
              const SizedBox(height: 8),
              _Item(label: 'Status', value: user['ustatus'] == true ? 'Active' : 'Inactive'),
              const SizedBox(height: 8),
              _Item(label: 'Role', value: user['role']?['utype_name'] ?? '—'),
            ] else ...[
              const Text('No user data available'),
            ],
            const SizedBox(height: 24),
            const Text(
              'Note: User data fetched from API',
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