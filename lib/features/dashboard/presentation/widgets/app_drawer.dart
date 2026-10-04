import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/authentication/presentation/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFFFDF7F0),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/dashboard',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: 'My Bookings',
                  route: '/bookings',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.event_note_outlined,
                  label: 'Calendar',
                  route: '/calendar',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.business_outlined,
                  label: 'Halls',
                  route: '/halls',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.analytics_outlined,
                  label: 'Reports',
                  route: '/reports',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.payments_outlined,
                  label: 'Pricing Settings',
                  route: '/settings',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE7DCC4)),
          _buildLogoutItem(context, ref),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Puranika Sadana',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'HALL MANAGER · SRI KSHETRA KOLLUR',
                  style: TextStyle(
                    color: const Color(0xFFE5D1B2).withValues(alpha: 0.8),
                    fontSize: 9,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final bool isSelected = GoRouterState.of(context).uri.path == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFFB5651D) : const Color(0xFF3D1608),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFFB5651D) : const Color(0xFF3D1608),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        context.pop(); // Close drawer
        if (!isSelected) {
          context.push(route);
        }
      },
    );
  }

  Widget _buildLogoutItem(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => _showLogoutConfirmation(context, ref),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Log out of Puranika Sadana?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              context.pop(); // Close drawer
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
