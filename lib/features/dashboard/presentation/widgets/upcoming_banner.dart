import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/booking_status.dart';
import '../../domain/models/booking.dart';

class UpcomingBanner extends ConsumerWidget {
  const UpcomingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return bookingsAsync.maybeWhen(
      data: (allBookings) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final sevenDaysLater = today.add(const Duration(days: 7));

        // Filter bookings for this week (inclusive) and confirmed status
        final upcomingThisWeek = allBookings.where((b) {
          final eventDate = DateTime(b.eventDate.year, b.eventDate.month, b.eventDate.day);
          return b.status == BookingStatus.confirmed &&
              !eventDate.isBefore(today) &&
              !eventDate.isAfter(sevenDaysLater);
        }).toList();

        if (upcomingThisWeek.isEmpty) {
          return const SizedBox.shrink(); // Hide the card entirely if zero bookings
        }

        // Find the SOONEST upcoming one
        upcomingThisWeek.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        final nextBooking = upcomingThisWeek.first;
        final count = upcomingThisWeek.length;
        final formattedDate = DateFormat('dd MMM yyyy').format(nextBooking.eventDate);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_outlined, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Upcoming This Week',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Next: ${nextBooking.hall.name} — $formattedDate',
                      style: TextStyle(
                        color: const Color(0xFFE5D1B2).withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  children: [
                    Text(
                      'View Calendar',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
