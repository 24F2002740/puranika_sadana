import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'notification_service.dart';
import 'settings_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final now = DateTime.now();
    
    // Initialize services
    final settings = SettingsService();
    await settings.init();
    
    if (!settings.pushNotificationsEnabled) {
      return Future.value(true);
    }

    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString('persisted_bookings') ?? '[]';
    final List<dynamic> bookings = json.decode(bookingsJson);

    for (var b in bookings) {
      final eventDate = DateTime.parse(b['eventDate']);
      final status = b['status'];
      final totalAmount = (b['totalAmount'] ?? 0.0).toDouble();
      final advancePaid = (b['advancePaid'] ?? 0.0).toDouble();
      final balance = totalAmount - advancePaid;
      final bookingId = b['id'];
      final groomName = b['groomName'];
      final brideName = b['brideName'];

      final difference = eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;

      // 1. Upcoming Reminders (Admin-editable windows)
      if (status == 'upcoming' || status == 'confirmed') {
        if (difference == settings.firstReminderDays) {
          await _sendBookingNotification(
            id: bookingId.hashCode + settings.firstReminderDays,
            title: 'Booking Reminder: $difference Days to Go',
            body: 'Wedding of $groomName & $brideName is in $difference days.',
            bookingId: bookingId,
          );
        } else if (difference == settings.finalReminderDays) {
          await _sendBookingNotification(
            id: bookingId.hashCode + settings.finalReminderDays,
            title: 'Final Reminder: Event in ${settings.finalReminderDays} Day(s)',
            body: 'Wedding of $groomName & $brideName is scheduled for soon.',
            bookingId: bookingId,
          );
        }
      }

      // 2. Pending Balance Reminders
      if (settings.dailyBalanceReminders && balance > 0 && status != 'cancelled') {
        await _sendBookingNotification(
          id: bookingId.hashCode + 100,
          title: 'Pending Balance Alert',
          body: 'Outstanding balance of ₹$balance for $groomName & $brideName.',
          bookingId: bookingId,
        );
      }
    }

    return Future.value(true);
  });
}

Future<void> _sendBookingNotification({
  required int id,
  required String title,
  required String body,
  required String bookingId,
}) async {
  // 1. Send Push Notification
  final notificationService = NotificationService();
  await notificationService.init(); 
  await notificationService.showNotification(
    id: id,
    title: title,
    body: body,
    payload: 'booking_$bookingId',
  );

  // 2. Add to In-app Notifications storage
  final prefs = await SharedPreferences.getInstance();
  final String? data = prefs.getString('app_notifications');
  List<dynamic> notifications = data != null ? json.decode(data) : [];
  
  notifications.insert(0, {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'title': title,
    'body': body,
    'timestamp': DateTime.now().toIso8601String(),
    'bookingId': bookingId,
    'isRead': false,
  });

  if (notifications.length > 50) {
    notifications = notifications.sublist(0, 50);
  }

  await prefs.setString('app_notifications', json.encode(notifications));
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> scheduleDailyCheck() async {
    await Workmanager().registerPeriodicTask(
      'daily_booking_check',
      'daily_booking_check',
      frequency: const Duration(hours: 24),
      initialDelay: _calculateInitialDelay(),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Duration _calculateInitialDelay() {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0); // 9:00 AM
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime.difference(now);
  }
}
