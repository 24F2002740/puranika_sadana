import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/app_notification.dart';
import 'bookings_provider.dart';
import '../../domain/models/booking_status.dart';
import '../../domain/models/booking.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  final Ref ref;
  NotificationsNotifier(this.ref) : super([]) {
    _init();
  }

  static const _readKey = 'read_notification_ids';

  void _init() {
    ref.listen(bookingsProvider, (previous, next) {
      next.whenData((bookings) {
        _generateAndLoad(bookings);
      });
    }, fireImmediately: true);
  }

  Future<void> _generateAndLoad(List<Booking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readKey) ?? [];

    final List<AppNotification> generated = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final booking in bookings) {
      if (booking.status == BookingStatus.confirmed) {
        final eventDate = DateTime(booking.eventDate.year, booking.eventDate.month, booking.eventDate.day);
        final diffDays = eventDate.difference(today).inDays;
        
        // Fix 1: Only keep wedding reminders (3 days and 1 day before)
        if (diffDays == 3) {
          final id = '3days_${booking.id}';
          generated.add(AppNotification(
            id: id,
            title: 'Wedding in 3 days',
            body: '3 days left — ${booking.displayGroomName} & ${booking.displayBrideName}\n${booking.hall.name}',
            timestamp: now.subtract(const Duration(hours: 2)),
            type: NotificationType.weddingReminder,
            bookingId: booking.id,
            isRead: readIds.contains(id),
          ));
        }

        if (diffDays == 1) {
          final id = '1day_${booking.id}';
          generated.add(AppNotification(
            id: id,
            title: 'Wedding Tomorrow',
            body: '1 day left — ${booking.displayGroomName} & ${booking.displayBrideName}\n${booking.hall.name}',
            timestamp: now.subtract(const Duration(hours: 1)),
            type: NotificationType.weddingReminder,
            bookingId: booking.id,
            isRead: readIds.contains(id),
          ));
        }
      }
    }

    generated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = generated;
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readKey) ?? [];
    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setStringList(_readKey, readIds);
    }
    
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
