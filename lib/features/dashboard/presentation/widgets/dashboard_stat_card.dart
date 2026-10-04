import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/booking_status.dart';

class DashboardStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool showDivider;

  const DashboardStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.gold, size: 20),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE5D1B2),
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (showDivider)
            Container(
              height: 30,
              width: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }
}

class DashboardStatsRow extends ConsumerWidget {
  const DashboardStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: bookingsAsync.when(
        data: (bookings) {
          final now = DateTime.now();
          final todayBookings = bookings.where((b) => 
            b.eventDate.year == now.year && 
            b.eventDate.month == now.month && 
            b.eventDate.day == now.day &&
            b.status != BookingStatus.cancelled
          ).length;

          final todayRevenue = bookings.where((b) {
            return b.paymentHistory.any((p) => 
              p.date.year == now.year && 
              p.date.month == now.month && 
              p.date.day == now.day
            );
          }).fold(0.0, (sum, b) {
            final todayPayments = b.paymentHistory.where((p) => 
              p.date.year == now.year && 
              p.date.month == now.month && 
              p.date.day == now.day
            ).fold(0.0, (s, p) => s + p.amount);
            return sum + todayPayments;
          });

          final pendingApprovals = bookings.where((b) => b.status == BookingStatus.pending).length;
          final totalBookings = bookings.where((b) => b.status != BookingStatus.cancelled).length;

          final currencyFormat = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN');

          return Row(
            children: [
              DashboardStatItem(
                icon: Icons.calendar_today_outlined,
                value: todayBookings.toString(),
                label: "Today's\nBookings",
              ),
              DashboardStatItem(
                icon: Icons.account_balance_wallet_outlined,
                value: currencyFormat.format(todayRevenue),
                label: "Today's\nRevenue",
              ),
              DashboardStatItem(
                icon: Icons.hourglass_empty_rounded,
                value: pendingApprovals.toString(),
                label: "Pending\nApprovals",
              ),
              DashboardStatItem(
                icon: Icons.trending_up_rounded,
                value: totalBookings.toString(),
                label: "Total\nBookings",
                showDivider: false,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (err, stack) => const Center(child: Text('Error', style: TextStyle(color: Colors.white))),
      ),
    );
  }
}
