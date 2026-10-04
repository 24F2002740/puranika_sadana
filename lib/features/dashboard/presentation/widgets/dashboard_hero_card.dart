import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Hero Banner
        Container(
          width: double.infinity,
          height: 340,
          decoration: const BoxDecoration(
            color: AppColors.primary,
          ),
          child: Stack(
            children: [
              // Goddess Mookambika Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/mookambika.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              // Dark gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.8),
                        AppColors.primary,
                      ],
                      stops: const [0.5, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
              // Text Content
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      '।। ಶ್ರೀ ಮೂಕಾಂಬಿಕಾ ಪ್ರಸನ್ನ ।।',
                      style: TextStyle(
                        color: Color(0xFFE5D1B2),
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Puranika Sadana',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Sri Kshetra Kollur',
                      style: TextStyle(
                        color: Color(0xFFE5D1B2),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Date Card (Section 3)
        Positioned(
          bottom: -25,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7F0),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
