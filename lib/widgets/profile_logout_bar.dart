import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // ADD THIS
import 'responsive_widgets.dart';
import '../session_manager.dart';

class ProfileLogoutBar extends StatelessWidget {
  const ProfileLogoutBar({super.key});

  Future<void> _logout(BuildContext context) async {
    // REPLACE with auth service
    await AuthService.clearAuthData();
    await SessionManager.logout(); // Keep for backward compatibility
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