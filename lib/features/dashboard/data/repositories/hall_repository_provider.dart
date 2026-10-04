import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hall_repository.dart';

final hallRepositoryProvider = Provider<HallRepository>((ref) {
  return HallRepository();
});

final watchHallsProvider = StreamProvider((ref) {
  return ref.watch(hallRepositoryProvider).watchHalls();
});
