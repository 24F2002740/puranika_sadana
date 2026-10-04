import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notifications_provider.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/booking.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1608),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(context, ref, notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: const Color(0xFF3D1608).withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D1608).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Important alerts about your bookings\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    final bool isBookingAlert = notification.bookingId != null;
    final bookingsAsync = ref.watch(bookingsProvider);
    Booking? booking;
    
    bookingsAsync.whenData((list) {
      booking = list.where((b) => b.id == notification.bookingId).firstOrNull;
    });

    return InkWell(
      onTap: () {
        ref.read(notificationsProvider.notifier).markAsRead(notification.id);
        if (isBookingAlert) {
          context.push('/booking-details/${notification.bookingId}');
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFFDFAF2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFE7DCC4)
                : const Color(0xFFB5651D).withOpacity(0.3),
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFB5651D).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (notification.isRead ? Colors.grey : const Color(0xFFB5651D))
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBookingAlert ? Icons.event_note_rounded : Icons.notifications_active_rounded,
                    color: notification.isRead ? Colors.grey : const Color(0xFFB5651D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight:
                                    notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF3D1608),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB5651D),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isBookingAlert && booking != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callContact(context, booking!.contact1),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text("Call"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3D1608),
                        side: const BorderSide(color: Color(0xFF3D1608)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendWhatsApp(context, booking!, notification),
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text("WhatsApp"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _callContact(BuildContext context, String phone) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch phone dialer")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error launching dialer: $e")),
        );
      }
    }
  }

  Future<void> _sendWhatsApp(BuildContext context, Booking booking, AppNotification notification) async {
    final phone = booking.contact1.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return;
    
    final formattedPhone = phone.length == 10 ? '91$phone' : phone;
    
    String message = "";
    if (notification.id.contains('3days')) {
      message = "Reminder: your wedding at ${booking.hall.name} is in 3 days.";
    } else if (notification.id.contains('1day')) {
      message = "Reminder: your wedding at ${booking.hall.name} is tomorrow.";
    }

    final url = "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);
    
    try {
      // mode: LaunchMode.externalApplication is recommended for deep linking to apps like WhatsApp
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch WhatsApp")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error launching WhatsApp: $e")),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(timestamp);
    }
  }
}
