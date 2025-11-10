import 'package:flutter/material.dart';
import '../session_manager.dart';
import 'responsive_widgets.dart'; // <-- to use ResponsiveButton

class ProfileLogoutBar extends StatelessWidget {
  const ProfileLogoutBar({super.key});

  Future<void> _logout(BuildContext context) async {
    await SessionManager.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: ResponsiveButton(
              text: 'Profile',
              icon: Icons.person_outline,
              isExpanded: true,
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ResponsiveButton(
              text: 'Logout',
              icon: Icons.logout,
              isExpanded: true,
              onPressed: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
