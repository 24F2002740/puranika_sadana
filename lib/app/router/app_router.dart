import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/pages/splash_screen.dart';
import '../../features/authentication/presentation/pages/language_selection_screen.dart';
import '../../features/authentication/presentation/pages/login_screen.dart';
import '../../features/authentication/presentation/pages/forgot_password_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/bookings_list_screen.dart';
import '../../features/dashboard/presentation/pages/booking_details_page.dart';
import '../../features/dashboard/presentation/pages/edit_booking_page.dart';
import '../../features/dashboard/presentation/pages/collect_balance_page.dart';
import '../../features/dashboard/presentation/pages/hall_management_page.dart';
import '../../screens/reports/reports_screen.dart';
import '../../features/dashboard/presentation/pages/calendar_page.dart';
import '../../features/dashboard/presentation/pages/settings_page.dart';
import '../../features/dashboard/presentation/widgets/booking_wizard_step1.dart';
import '../../features/dashboard/domain/models/booking.dart';
import '../../screens/certificate/aadhaar_scan_screen.dart';
import '../../screens/certificate/marriage_certificate_screen.dart';
import '../../screens/notifications/notifications_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingsListScreen(),
      ),
      GoRoute(
        path: '/booking-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabStr ?? '0') ?? 0;
          return BookingDetailsPage(bookingId: id, initialTab: initialTab);
        },
      ),
      GoRoute(
        path: '/edit-booking',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return EditBookingPage(booking: booking);
        },
      ),
      GoRoute(
        path: '/collect-balance',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return CollectBalancePage(booking: booking);
        },
      ),
      GoRoute(
        path: '/halls',
        builder: (context, state) {
          final index = state.extra as int? ?? 0;
          return HallManagementPage(initialIndex: index);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/more',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/new-booking',
        builder: (context, state) => const BookingWizardStep1(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(
        path: '/aadhaar-scan',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return AadhaarScanScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/marriage-certificate',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return MarriageCertificateScreen(booking: booking);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('No route defined for ${state.uri.path}'),
      ),
    ),
  );
}
