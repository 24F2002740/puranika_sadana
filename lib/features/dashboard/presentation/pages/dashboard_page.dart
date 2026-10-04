import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_hero_card.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/dashboard_quick_action_card.dart';
import '../widgets/dashboard_bottom_navigation.dart';
import '../widgets/dashboard_section_header.dart';
import '../widgets/hall_status_card.dart';
import '../widgets/booking_card.dart';
import '../widgets/upcoming_banner.dart';
import '../widgets/upcoming_reminders_section.dart';
import '../widgets/app_drawer.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/booking_status.dart';
import '../../domain/models/hall.dart';
import '../../domain/models/booking.dart';
import '../../data/repositories/hall_repository_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final hallsAsync = ref.watch(watchHallsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: const DashboardAppBar(),
      drawer: const AppDrawer(),
      body: bookingsAsync.when(
        data: (allBookings) => hallsAsync.when(
          data: (halls) => _buildContent(context, allBookings, halls),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: const DashboardBottomNavigation(),
    );
  }

  Widget _buildContent(BuildContext context, List<Booking> allBookings, List<Hall> halls) {
    final recentBookings = allBookings
        .where((b) => b.status != BookingStatus.cancelled)
        .toList()
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
    
    final displayBookings = recentBookings.take(2).toList();
    final activeHalls = halls.where((h) => h.isActive).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 2 & 3: Hero Banner & Date Card
          const DashboardHeroCard(),
          
          const SizedBox(height: 50), // Spacing for the overlapping date card

          // Section 4: Stats Row
          const DashboardStatsRow(),

          const SizedBox(height: 24),

          // Section 5: Quick Actions
          const DashboardSectionHeader(
            kannadaTitle: 'ತ್ವರಿತ ಕಾರ್ಯಗಳು',
            englishTitle: 'Quick Actions',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DashboardQuickActionCard(
                  label: 'New\nBooking',
                  icon: Icons.add_circle_outline_rounded,
                  onTap: () => context.push('/new-booking'),
                ),
                DashboardQuickActionCard(
                  label: 'All\nBookings',
                  icon: Icons.calendar_month_rounded,
                  onTap: () => context.push('/bookings'),
                ),
                DashboardQuickActionCard(
                  label: 'Halls',
                  icon: Icons.business_rounded,
                  onTap: () => context.push('/halls', extra: 0),
                ),
                DashboardQuickActionCard(
                  label: 'Reports',
                  icon: Icons.description_outlined,
                  onTap: () => context.push('/reports'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Section: Upcoming Reminders (New)
          const UpcomingRemindersSection(),

          const SizedBox(height: 24),

          // Section 6: Halls Status
          DashboardSectionHeader(
            kannadaTitle: 'ಹಾಲ್‌ಗಳ ಸ್ಥಿತಿ',
            englishTitle: 'Halls Status',
            onViewAll: () => context.push('/halls', extra: 0),
          ),
          
          ...activeHalls.map((hall) => HallStatusCard(
            name: hall.name,
            capacity: '${hall.capacity} Seats',
            price: '₹${NumberFormat('#,##,###').format(hall.packageRate)}',
            isAvailable: _isHallAvailable(allBookings, hall, DateTime.now()),
            onTap: () => context.push('/halls', extra: halls.indexOf(hall)),
          )),

          const SizedBox(height: 24),

          // Section 7: Recent Bookings
          DashboardSectionHeader(
            kannadaTitle: 'ನನ್ನ ಬುಕಿಂಗ್‌ಗಳು',
            englishTitle: 'Recent',
            onViewAll: () => context.push('/bookings'),
          ),
          if (displayBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text('No recent bookings found.'),
            )
          else
            ...displayBookings.map((b) => BookingCard(
                  bookingId: b.id,
                  shortHallName: b.hall.name,
                  status: b.status,
                  hallFullName: b.hall.name,
                  groomName: b.groomName,
                  brideName: b.brideName,
                  date: DateFormat('dd MMM yyyy').format(b.eventDate),
                  time: b.startTime != null ? '${b.startTime!.format(context)} onwards' : 'TBD',
                  guests: '${b.guestCount} Guests',
                  amount: '₹${NumberFormat('#,##,###').format(b.totalAmount)}',
                  onTap: () => context.push('/booking-details/${b.id}'),
                )),

          // Section 8: Upcoming Banner
          const UpcomingBanner(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  bool _isHallAvailable(List<Booking> bookings, Hall hall, DateTime date) {
    return !bookings.any((b) =>
        b.hall.id == hall.id &&
        b.eventDate.year == date.year &&
        b.eventDate.month == date.month &&
        b.eventDate.day == date.day &&
        b.status != BookingStatus.cancelled);
  }
}
