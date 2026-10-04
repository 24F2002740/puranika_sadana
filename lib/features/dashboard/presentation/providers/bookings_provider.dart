import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/booking.dart';
import '../../data/repositories/booking_repository_provider.dart';

final bookingsProvider = StreamProvider<List<Booking>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.watchBookings();
});
