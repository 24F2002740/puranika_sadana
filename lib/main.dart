import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:puranika_sadana/l10n/app_localizations.dart';
import 'package:puranika_sadana/core/services/pricing_service.dart';
import 'package:puranika_sadana/core/services/notification_service.dart';
import 'package:puranika_sadana/core/services/background_service.dart';
import 'package:puranika_sadana/core/services/settings_service.dart';
import 'package:puranika_sadana/features/dashboard/data/repositories/hall_repository_provider.dart';

import 'firebase_options.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/services/locale_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Core Services
  final pricingService = PricingService();
  await pricingService.init();

  final settingsService = SettingsService();
  await settingsService.init();

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Initialize Background Service (WorkManager)
  // Initialize Background Service (WorkManager)
  await BackgroundService.init();
  await BackgroundService.scheduleDailyCheck();

  // Create Riverpod container
  final container = ProviderContainer();

  // Start the app FIRST.
  // Do not wait for Firestore hall seeding before runApp().
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PuranikaSadanaApp(),
    ),
  );

  // Seed halls after the UI has started.
  try {
    await container.read(hallRepositoryProvider).seedHallsIfEmpty();
  } catch (e) {
    debugPrint('Hall seeding error: $e');
  }
}

class PuranikaSadanaApp extends ConsumerStatefulWidget {
  const PuranikaSadanaApp({super.key});

  @override
  ConsumerState<PuranikaSadanaApp> createState() => _PuranikaSadanaAppState();
}

class _PuranikaSadanaAppState extends ConsumerState<PuranikaSadanaApp> {
  @override
  void initState() {
    super.initState();
    
    // 1. Handle background/foreground taps while app is running
    NotificationService().onNotificationTap.listen((bookingId) {
      _handleDeepLink(bookingId);
    });

    // 2. Handle app launch from notification (terminated state)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialId = NotificationService().initialBookingId;
      if (initialId != null) {
        _handleDeepLink(initialId);
        NotificationService().consumeInitialBookingId();
      }
    });
  }

  void _handleDeepLink(String bookingId) {
    AppRouter.router.push('/booking-details/$bookingId');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Puranika Sadana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      locale: locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
