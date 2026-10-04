import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/hall.dart';

class HallRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'halls';

  HallRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveHall(Hall hall) async {
    if (hall.id.isEmpty) {
      final docRef = _firestore.collection(_collection).doc();
      final newHall = hall.copyWith(id: docRef.id);
      await docRef.set(newHall.toMap());
    } else {
      await _firestore.collection(_collection).doc(hall.id).set(hall.toMap(), SetOptions(merge: true));
    }
  }

  Future<List<Hall>> getHalls() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) => Hall.fromMap(doc.data(), doc.id)).toList();
  }

  Stream<List<Hall>> watchHalls() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Hall.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> seedHallsIfEmpty() async {
    final halls = await getHalls();
    if (halls.isEmpty) {
      final bigHall = Hall(
        id: '',
        name: 'Puranika Sabha Sadana',
        location: 'Sri Kshetra Kollur',
        capacity: 350,
        packageRate: 32000,
        cleaningCharge: 2500,
        photoPaths: [
          'assets/images/logo.png', // Placeholder as asset
        ],
        facilities: [
          'ಹಾಲ್ + ಮಂಟಪ + ಡೆಕೋರೇಶನ್ + ಕೂಲರ್',
          'ಮಹಾರಾಜ ಸೋಫಾ + ನೇಮ್ ಬೋರ್ಡ್ +',
          'ಸೌಂಡ್ ಸಿಸ್ಟಮ್ + 2 ಡ್ರೆಸ್ಸಿಂಗ್ ರೂಂ + ಜನರೇಟರ್',
          'ಪುರೋಹಿತರು +',
          'ಪೂಜಾ ಸಾಮಾನು (ಧಾರೆ + ಹೋಮ + ಸಪ್ತಪದಿ)',
          'ವಿವಾಹ ಸರ್ಟಿಫಿಕೇಟ್ (ಆಧಾರ್ ಕಾರ್ಡ್ + ಲಗ್ನ ಪತ್ರಿಕೆ) ತರಬೇಕು',
          'ದೇವರ ದರ್ಶನ - (4-6 ಜನ)',
        ],
        isActive: true,
      );

      final smallHall = Hall(
        id: '',
        name: 'Puranika Sadana',
        location: 'Sri Kshetra Kollur',
        capacity: 100,
        packageRate: 20000,
        cleaningCharge: 1500,
        photoPaths: [
           'assets/images/logo.png', // Placeholder
        ],
        facilities: [
          'ಹಾಲ್ + ಮಂಟಪ + ಡೆಕೋರೇಶನ್ + ಕೂಲರ್',
          'ಮಹಾರಾಜ ಸೋಫಾ + ಸೌಂಡ್ ಸಿಸ್ಟಮ್',
          'ಜನರೇಟರ್ + 1 ಡ್ರೆಸ್ಸಿಂಗ್ ರೂಂ',
          'ಪುರೋಹಿತರು +',
          'ಪೂಜಾ ಸಾಮಾನು (ಧಾರೆ + ಹೋಮ + ಸಪ್ತಪದಿ)',
          'ವಿವಾಹ ಸರ್ಟಿಫಿಕೇಟ್ (ಆಧಾರ್ ಕಾರ್ಡ್ ತರಬೇಕು)',
          'ದೇವರ ದರ್ಶನ + (4-6 ಜನ)',
        ],
        isActive: true,
      );

      await saveHall(bigHall);
      await saveHall(smallHall);
    }
  }
}
