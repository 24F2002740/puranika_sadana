import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine current index based on route
    final String location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/bookings')) {
      currentIndex = 1;
    } else if (location.startsWith('/calendar')) {
      currentIndex = 2;
    } else if (location.startsWith('/halls')) {
      currentIndex = 3;
    } else if (location.startsWith('/more')) {
      currentIndex = 4;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: const Color(0xFFE5D1B2).withValues(alpha: 0.5),
        currentIndex: currentIndex,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          _buildNavItem(Icons.home_rounded, 'Dashboard', 'ಮುಖಪುಟ'),
          _buildNavItem(Icons.event_note_rounded, 'Bookings', 'ಬುಕಿಂಗ್‌ಗಳು'),
          _buildNavItem(Icons.calendar_month_rounded, 'Calendar', 'ಕ್ಯಾಲೆಂಡರ್'),
          _buildNavItem(Icons.business_rounded, 'Halls', 'ಹಾಲ್‌ಗಳು'),
          _buildNavItem(Icons.more_horiz_rounded, 'More', 'ಹೆಚ್ಚು'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/bookings');
              break;
            case 2:
              context.go('/calendar');
              break;
            case 3:
              context.go('/halls');
              break;
            case 4:
              context.go('/more');
              break;
          }
        },
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, String kannadaLabel) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: kannadaLabel,
    );
  }
}
