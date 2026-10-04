import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String kannadaTitle;
  final String englishTitle;
  final VoidCallback? onViewAll;

  const DashboardSectionHeader({
    super.key,
    required this.kannadaTitle,
    required this.englishTitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            kannadaTitle,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            englishTitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
