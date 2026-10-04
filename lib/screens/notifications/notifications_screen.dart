import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/dashboard/presentation/providers/notifications_provider.dart';
import '../../features/dashboard/presentation/providers/bookings_provider.dart';
import '../../features/dashboard/domain/models/app_notification.dart';
import '../../features/dashboard/domain/models/booking.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

    Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
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

  Future<void> _launchWhatsApp(BuildContext context, String phoneNumber, String message) async {
    if (phoneNumber.isEmpty) return;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    
    final whatsappUrl = "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(whatsappUrl);
    
    try {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final bookingsAsync = ref.watch(bookingsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: bookingsAsync.when(
          data: (bookings) {
            if (notifications.isEmpty) return _buildEmptyState();
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                
                final bookingIndex = bookings.indexWhere((b) => b.id == notification.bookingId);
                if (bookingIndex == -1) return const SizedBox.shrink();
                
                final booking = bookings[bookingIndex];
                
                return _buildNotificationCard(context, ref, notification, booking);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
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
          const Text(
            'No notifications right now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0x7F3D1608),
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
    Booking booking,
  ) {
    // Fix 1: Removed balanceDue logic. Notifications are now only wedding reminders.
    const icon = Icons.calendar_today_rounded;
    const iconColor = Color(0xFFB5651D);

    return InkWell(
      onTap: () {
        ref.read(notificationsProvider.notifier).markAsRead(notification.id);
        context.push('/booking-details/${notification.bookingId}?tab=0');
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
                : iconColor.withOpacity(0.3),
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: iconColor.withOpacity(0.05),
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
                    color: (notification.isRead ? Colors.grey : iconColor)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: notification.isRead ? Colors.grey : iconColor,
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
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
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
                                color: iconColor,
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
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatRelativeTime(notification.timestamp),
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE7DCC4)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildQuickAction(
                  Icons.phone_outlined,
                  'Call',
                  () => _makePhoneCall(context, booking.contact1),
                ),
                const SizedBox(width: 16),
                _buildQuickAction(
                  Icons.chat_outlined,
                  'WhatsApp',
                  () {
                    // Fix 2: Pre-filled WhatsApp message logic using wa.me and encoded message
                    final String msg;
                    if (notification.id.contains('3days')) {
                      msg = "Reminder: your wedding of ${booking.displayGroomName} & ${booking.displayBrideName} at ${booking.hall.name} is in 3 days.";
                    } else if (notification.id.contains('1day')) {
                      msg = "Reminder: your wedding of ${booking.displayGroomName} & ${booking.displayBrideName} at ${booking.hall.name} is tomorrow.";
                    } else {
                      msg = "Wedding reminder from Puranika Sadana for ${booking.displayGroomName} & ${booking.displayBrideName}.";
                    }

                    _launchWhatsApp(context, booking.contact1, msg);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFB5651D)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB5651D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
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
