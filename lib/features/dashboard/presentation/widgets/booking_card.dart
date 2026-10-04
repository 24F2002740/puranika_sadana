import 'package:flutter/material.dart';
import 'package:puranika_sadana/core/constants/app_colors.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/booking_status.dart';
import 'package:puranika_sadana/features/dashboard/presentation/widgets/status_pill.dart';

class BookingCard extends StatelessWidget {
  final String bookingId;
  final String shortHallName;
  final BookingStatus status;
  final String hallFullName;
  final String groomName;
  final String brideName;
  final String date;
  final String time;
  final String guests;
  final String amount;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.bookingId,
    required this.shortHallName,
    required this.status,
    required this.hallFullName,
    required this.groomName,
    required this.brideName,
    required this.date,
    required this.time,
    required this.guests,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F4A0E14),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bookingId,
                      style: const TextStyle(
                        color: Color(0xFFE5D1B2),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      shortHallName,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  StatusPill(status: status),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hallFullName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Chi. $groomName & Chi.Sou. $brideName',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Flexible(child: _buildIconInfo(Icons.calendar_month_outlined, date)),
                            const SizedBox(width: 8),
                            Flexible(child: _buildIconInfo(Icons.access_time_rounded, time)),
                            const SizedBox(width: 8),
                            Flexible(child: _buildIconInfo(Icons.people_outline_rounded, guests)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          amount,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        'Total Amount',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
