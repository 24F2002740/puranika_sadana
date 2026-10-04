import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/booking_status.dart';
import '../../domain/models/booking.dart';
import 'dashboard_section_header.dart';

class UpcomingRemindersSection extends ConsumerWidget {
  const UpcomingRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final now = DateTime.now();
        final upcomingReminders = bookings.where((b) {
          if (b.status == BookingStatus.cancelled || b.status == BookingStatus.completed) return false;
          final difference = b.eventDate.difference(now).inDays;
          return difference >= 0 && difference <= 3;
        }).toList()
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

        final displayList = upcomingReminders.take(5).toList();

        if (displayList.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardSectionHeader(
              kannadaTitle: 'ಮುಂಬರುವ ಜ್ಞಾಪನೆಗಳು',
              englishTitle: 'Upcoming Reminders',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final booking = displayList[index];
                  final daysLeft = booking.eventDate.difference(now).inDays;
                  
                  return _ReminderCard(
                    booking: booking,
                    daysLeft: daysLeft,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Booking booking;
  final int daysLeft;

  const _ReminderCard({
    required this.booking,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUrgent = daysLeft <= 1;
    final color = isUrgent ? AppColors.error : AppColors.primary;

    return GestureDetector(
      onTap: () => context.push('/booking-details/${booking.id}'),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUrgent ? Icons.priority_high : Icons.notifications_active_outlined,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${booking.brideName} & ${booking.groomName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM').format(booking.eventDate),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUrgent ? 'Happening Tomorrow!' : 'In $daysLeft days',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
