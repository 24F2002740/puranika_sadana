import 'package:flutter/material.dart';

enum BookingStatus {
  upcoming,
  confirmed,
  pending,
  completed,
  cancelled;

  String toDisplayString() {
    switch (this) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.upcoming:
      case BookingStatus.confirmed:
      case BookingStatus.pending:
        return const Color(0xFFB5651D); // Amber
      case BookingStatus.completed:
        return const Color(0xFF7FAE5B); // Green
      case BookingStatus.cancelled:
        return const Color(0xFFA53D30); // Red
    }
  }

  Color get bgColor {
    return color.withValues(alpha: 0.1);
  }
}
