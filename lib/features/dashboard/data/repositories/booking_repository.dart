import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/booking.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'bookings';

  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> createBooking(Booking booking) async {
    final String customId = await _generateCustomId(booking);
    final docRef = _firestore.collection(_collection).doc(customId);
    final newBooking = booking.copyWith(id: customId);
    await docRef.set(newBooking.toMap());
    return customId;
  }

  Future<String> _generateCustomId(Booking booking) async {
    final String dateStr = DateFormat('ddMMyy').format(booking.eventDate);
    
    // ignore the "Chi." prefix for groom and "Chi.Sou." for bride
    String cleanGroom = _stripPrefixes(booking.groomName, ['Chi.Sou.', 'Chi.Sou', 'Chi.', 'Chi']);
    String cleanBride = _stripPrefixes(booking.brideName, ['Chi.Sou.', 'Chi.Sou', 'Chi.', 'Chi']);
    
    final String g3 = _getThreeLetters(cleanGroom);
    final String b3 = _getThreeLetters(cleanBride);
    
    final String baseId = '${AppConstants.cityCode}-$dateStr-$g3$b3';
    
    String finalId = baseId;
    int suffix = 2;
    
    while (true) {
      final doc = await _firestore.collection(_collection).doc(finalId).get();
      if (!doc.exists) break;
      finalId = '$baseId-$suffix';
      suffix++;
    }
    
    return finalId;
  }

  String _stripPrefixes(String name, List<String> prefixes) {
    String cleaned = name.trim();
    // Sort prefixes by length descending to avoid partial matches
    final sortedPrefixes = List<String>.from(prefixes)..sort((a, b) => b.length.compareTo(a.length));
    
    for (var prefix in sortedPrefixes) {
      if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
        cleaned = cleaned.substring(prefix.length).trim();
        break; 
      }
    }
    return cleaned;
  }

  String _getThreeLetters(String name) {
    // Only take alphabetic characters for the ID part
    final String onlyLetters = name.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (onlyLetters.length >= 3) {
      return onlyLetters.substring(0, 3).toUpperCase();
    }
    return onlyLetters.padRight(3, 'X').toUpperCase();
  }

  Future<void> updateBooking(Booking booking) async {
    await _firestore.collection(_collection).doc(booking.id).update(booking.toMap());
  }

  Future<Booking?> getBooking(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Booking.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<Booking>> watchBookings() {
    return _firestore
        .collection(_collection)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> deleteBooking(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
