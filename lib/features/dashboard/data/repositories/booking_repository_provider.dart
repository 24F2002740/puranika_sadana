import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});
