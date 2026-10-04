import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../features/dashboard/domain/models/booking.dart';
import '../features/dashboard/domain/models/booking_status.dart';

class ReportSummary {
  final int bookingCount;
  final double totalRevenue;
  final double totalAdvance;
  final double totalBalance;
  final List<BreakdownItem> breakdown;

  ReportSummary({
    required this.bookingCount,
    required this.totalRevenue,
    required this.totalAdvance,
    required this.totalBalance,
    this.breakdown = const [],
  });
}

class BreakdownItem {
  final String label;
  final double value;
  final int count;

  BreakdownItem({
    required this.label,
    required this.value,
    this.count = 0,
  });
}

class HallSummary {
  final String hallName;
  final int bookingCount;
  final double revenue;

  HallSummary({
    required this.hallName,
    required this.bookingCount,
    required this.revenue,
  });
}

class ReportsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Safe helpers
  // ---------------------------------------------------------------------------

  double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return defaultValue;
    }

    return double.tryParse(value.toString()) ?? defaultValue;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String _parseStatus(dynamic value) {
    return value?.toString() ?? 'pending';
  }

  // IMPORTANT:
  // Old records may contain:
  //   hall: 1
  //   hall: "1"
  //
  // New records may contain:
  //   hall: { id: "...", name: "...", ... }
  //
  // Never cast hall directly to Map.
  String _getHallName(dynamic hallData) {
    if (hallData is Map) {
      final hallMap = Map<String, dynamic>.from(hallData);

      final name = hallMap['name'];

      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }

      return 'Unknown Hall';
    }

    // Legacy hall value.
    if (hallData != null) {
      final value = hallData.toString().trim();

      if (value.isNotEmpty) {
        return 'Hall $value';
      }
    }

    return 'Unknown Hall';
  }

  // ---------------------------------------------------------------------------
  // Daily Summary
  // ---------------------------------------------------------------------------

  Future<ReportSummary> getDailySummary(DateTime date) async {
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    final snapshot = await _db
        .collection('bookings')
        .where(
      'eventDate',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
    )
        .where(
      'eventDate',
      isLessThan: Timestamp.fromDate(endOfDay),
    )
        .get();

    return _processBookings(snapshot.docs);
  }

  // ---------------------------------------------------------------------------
  // Monthly Summary
  // ---------------------------------------------------------------------------

  Future<ReportSummary> getMonthlySummary(
      int year,
      int month,
      ) async {
    final startOfMonth = DateTime(
      year,
      month,
      1,
    );

    final endOfMonth = DateTime(
      year,
      month + 1,
      1,
    );

    final snapshot = await _db
        .collection('bookings')
        .where(
      'eventDate',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
    )
        .where(
      'eventDate',
      isLessThan: Timestamp.fromDate(endOfMonth),
    )
        .get();

    final bookings = snapshot.docs;

    final summary = _processBookings(bookings);

    // Day-by-day breakdown.
    final daysInMonth = DateTime(
      year,
      month + 1,
      0,
    ).day;

    final Map<int, double> dailyRevenue = {};

    for (int i = 1; i <= daysInMonth; i++) {
      dailyRevenue[i] = 0.0;
    }

    for (final doc in bookings) {
      final data = doc.data();

      final status = _parseStatus(
        data['status'],
      );

      if (status == BookingStatus.cancelled.name) {
        continue;
      }

      final eventDate = _parseDate(
        data['eventDate'],
      );

      if (eventDate == null) {
        continue;
      }

      final total = _parseDouble(
        data['totalAmount'],
      );

      dailyRevenue[eventDate.day] =
          (dailyRevenue[eventDate.day] ?? 0.0) + total;
    }

    final breakdown = dailyRevenue.entries
        .map(
          (entry) => BreakdownItem(
        label: entry.key.toString(),
        value: entry.value,
      ),
    )
        .toList();

    breakdown.sort(
          (a, b) =>
          int.parse(a.label).compareTo(
            int.parse(b.label),
          ),
    );

    return ReportSummary(
      bookingCount: summary.bookingCount,
      totalRevenue: summary.totalRevenue,
      totalAdvance: summary.totalAdvance,
      totalBalance: summary.totalBalance,
      breakdown: breakdown,
    );
  }

  // ---------------------------------------------------------------------------
  // Yearly Summary
  // ---------------------------------------------------------------------------

  Future<ReportSummary> getYearlySummary(
      int year,
      ) async {
    final startOfYear = DateTime(
      year,
      1,
      1,
    );

    final endOfYear = DateTime(
      year + 1,
      1,
      1,
    );

    final snapshot = await _db
        .collection('bookings')
        .where(
      'eventDate',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
    )
        .where(
      'eventDate',
      isLessThan: Timestamp.fromDate(endOfYear),
    )
        .get();

    final bookings = snapshot.docs;

    final summary = _processBookings(bookings);

    // Month-by-month breakdown.
    final Map<int, double> monthlyRevenue = {};

    for (int i = 1; i <= 12; i++) {
      monthlyRevenue[i] = 0.0;
    }

    for (final doc in bookings) {
      final data = doc.data();

      final status = _parseStatus(
        data['status'],
      );

      if (status == BookingStatus.cancelled.name) {
        continue;
      }

      final eventDate = _parseDate(
        data['eventDate'],
      );

      if (eventDate == null) {
        continue;
      }

      final total = _parseDouble(
        data['totalAmount'],
      );

      monthlyRevenue[eventDate.month] =
          (monthlyRevenue[eventDate.month] ?? 0.0) + total;
    }

    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final breakdown = monthlyRevenue.entries
        .map(
          (entry) => BreakdownItem(
        label: monthNames[entry.key - 1],
        value: entry.value,
      ),
    )
        .toList();

    return ReportSummary(
      bookingCount: summary.bookingCount,
      totalRevenue: summary.totalRevenue,
      totalAdvance: summary.totalAdvance,
      totalBalance: summary.totalBalance,
      breakdown: breakdown,
    );
  }

  // ---------------------------------------------------------------------------
  // Hall-wise Summary
  // ---------------------------------------------------------------------------

  Future<List<HallSummary>> getHallWiseSummary(
      DateTimeRange range,
      ) async {
    final snapshot = await _db
        .collection('bookings')
        .where(
      'eventDate',
      isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
    )
        .where(
      'eventDate',
      isLessThanOrEqualTo: Timestamp.fromDate(range.end),
    )
        .get();

    final Map<String, HallSummary> hallData = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = _parseStatus(
        data['status'],
      );

      if (status == BookingStatus.cancelled.name) {
        continue;
      }

      // FIX:
      // Do NOT do:
      //
      // final hallMap = data['hall'] as Map<String, dynamic>?;
      //
      // because old records may contain an int/string.
      final hallName = _getHallName(
        data['hall'],
      );

      final total = _parseDouble(
        data['totalAmount'],
      );

      if (hallData.containsKey(hallName)) {
        final current = hallData[hallName]!;

        hallData[hallName] = HallSummary(
          hallName: hallName,
          bookingCount: current.bookingCount + 1,
          revenue: current.revenue + total,
        );
      } else {
        hallData[hallName] = HallSummary(
          hallName: hallName,
          bookingCount: 1,
          revenue: total,
        );
      }
    }

    final result = hallData.values.toList();

    result.sort(
          (a, b) => a.hallName.compareTo(b.hallName),
    );

    return result;
  }

  // ---------------------------------------------------------------------------
  // Balance Due List
  // ---------------------------------------------------------------------------

  Future<List<Booking>> getBalanceDueList(
      DateTimeRange range,
      ) async {
    final snapshot = await _db
        .collection('bookings')
        .where(
      'eventDate',
      isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
    )
        .where(
      'eventDate',
      isLessThanOrEqualTo: Timestamp.fromDate(range.end),
    )
        .get();

    final List<Booking> dueBookings = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = _parseStatus(
        data['status'],
      );

      // Ignore cancelled bookings.
      if (status == BookingStatus.cancelled.name) {
        continue;
      }

      final total = _parseDouble(
        data['totalAmount'],
      );

      final advance = _parseDouble(
        data['advancePaid'],
      );

      final balance = total - advance;

      if (balance > 0) {
        try {
          dueBookings.add(
            Booking.fromMap(
              data,
              doc.id,
            ),
          );
        } catch (e) {
          // If one old/corrupt booking cannot be converted,
          // don't crash the entire Reports screen.
          debugPrint(
            'Unable to parse booking ${doc.id}: $e',
          );
        }
      }
    }

    dueBookings.sort(
          (a, b) => a.eventDate.compareTo(
        b.eventDate,
      ),
    );

    return dueBookings;
  }

  // ---------------------------------------------------------------------------
  // Process Bookings
  // ---------------------------------------------------------------------------

  ReportSummary _processBookings(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    int count = 0;
    double revenue = 0.0;
    double advance = 0.0;
    double balance = 0.0;

    for (final doc in docs) {
      final data = doc.data();

      final status = _parseStatus(
        data['status'],
      );

      if (status == BookingStatus.cancelled.name) {
        continue;
      }

      count++;

      final total = _parseDouble(
        data['totalAmount'],
      );

      final adv = _parseDouble(
        data['advancePaid'],
      );

      revenue += total;
      advance += adv;
      balance += total - adv;
    }

    return ReportSummary(
      bookingCount: count,
      totalRevenue: revenue,
      totalAdvance: advance,
      totalBalance: balance,
    );
  }
}