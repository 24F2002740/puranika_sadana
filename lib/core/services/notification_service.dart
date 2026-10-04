import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../features/dashboard/domain/models/booking.dart';
import '../../features/dashboard/domain/models/booking_status.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  String? _initialBookingId;
  String? get initialBookingId => _initialBookingId;

  Future<void> init() async {
    tz.initializeTimeZones();
    // Default to IST for the temple business location
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      debugPrint('Timezone initialization error: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp && details.notificationResponse != null) {
      final String? payload = details.notificationResponse!.payload;
      if (payload != null && payload.startsWith('booking_')) {
        _initialBookingId = payload.replaceFirst('booking_', '');
      }
    }
    
    // Auto-resync on startup
    await resyncAllReminders();
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.startsWith('booking_')) {
      final bookingId = payload.replaceFirst('booking_', '');
      _notificationTapController.add(bookingId);
    }
  }

  static final StreamController<String> _notificationTapController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _notificationTapController.stream;

  void consumeInitialBookingId() {
    _initialBookingId = null;
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  int _getHash(String id) => id.hashCode.abs();

  Future<void> scheduleBookingReminders(Booking booking) async {
    // Cancel existing ones first to avoid duplicates or stale data
    await cancelBookingReminders(booking.id);

    // Only schedule for confirmed/upcoming/pending.
    if (booking.status == BookingStatus.cancelled || booking.status == BookingStatus.completed) {
      return;
    }

    final int baseId = _getHash(booking.id);
    final String names = '${booking.brideName} & ${booking.groomName}';
    final String hall = booking.hall.name;
    final double balance = booking.totalAmount - booking.advancePaid;
    final String dateStr = DateFormat('dd MMM yyyy').format(booking.eventDate);

    // 1. 3 Days Before at 9:00 AM
    final date3 = booking.eventDate.subtract(const Duration(days: 3));
    final reminderTime3 = DateTime(date3.year, date3.month, date3.day, 9, 0);
    
    if (reminderTime3.isAfter(DateTime.now())) {
      await _schedule(
        id: baseId + 3, 
        title: 'Upcoming Wedding Event',
        body: 'Upcoming event: $names — $hall on $dateStr. Balance due: ₹${balance.toInt()}',
        scheduledDate: reminderTime3,
        payload: 'booking_${booking.id}',
      );
    }

    // 2. 1 Day Before at 9:00 AM
    final date1 = booking.eventDate.subtract(const Duration(days: 1));
    final reminderTime1 = DateTime(date1.year, date1.month, date1.day, 9, 0);

    if (reminderTime1.isAfter(DateTime.now())) {
      await _schedule(
        id: baseId + 1,
        title: 'Reminder: Event Tomorrow!',
        body: 'URGENT: Wedding event tomorrow: $names at $hall. Balance due: ₹${balance.toInt()}',
        scheduledDate: reminderTime1,
        payload: 'booking_${booking.id}',
      );
    }
  }

  Future<void> cancelBookingReminders(String bookingId) async {
    final int baseId = _getHash(bookingId);
    await _notificationsPlugin.cancel(baseId + 3);
    await _notificationsPlugin.cancel(baseId + 1);
  }

  Future<void> resyncAllReminders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: [
            BookingStatus.confirmed.name, 
            BookingStatus.upcoming.name, 
            BookingStatus.pending.name
          ])
          .get();

      for (var doc in snapshot.docs) {
        final booking = Booking.fromMap(doc.data(), doc.id);
        if (booking.eventDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
          await scheduleBookingReminders(booking);
        }
      }
    } catch (e) {
      debugPrint('Error resyncing notifications: $e');
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_reminders',
      'Booking Reminders',
      channelDescription: 'Reminders for upcoming bookings and pending balances',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_reminders',
      'Booking Reminders',
      channelDescription: 'Daily reminders for upcoming bookings and pending balances',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails, payload: payload);
  }
}
