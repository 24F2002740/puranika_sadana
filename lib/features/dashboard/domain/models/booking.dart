import 'package:flutter/material.dart';
import 'booking_status.dart';
import 'hall.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentEntry {
  final DateTime date;
  final String method;
  final double amount;

  PaymentEntry({
    required this.date,
    required this.method,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'method': method,
      'amount': amount,
    };
  }

  factory PaymentEntry.fromMap(Map<String, dynamic> map) {
    return PaymentEntry(
      date: (map['date'] as Timestamp).toDate(),
      method: map['method'] ?? '',
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

class BookingCustomExtra {
  final String name;
  final double rate;
  final bool isFlat;

  BookingCustomExtra({
    required this.name,
    required this.rate,
    this.isFlat = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rate': rate,
      'isFlat': isFlat,
    };
  }

  factory BookingCustomExtra.fromMap(Map<String, dynamic> map) {
    return BookingCustomExtra(
      name: map['name'] ?? '',
      rate: (map['rate'] as num).toDouble(),
      isFlat: map['isFlat'] ?? false,
    );
  }
}

class BookingSavedExtra {
  final String name;
  final double amount;

  BookingSavedExtra({
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  factory BookingSavedExtra.fromMap(Map<String, dynamic> map) {
    return BookingSavedExtra(
      name: map['name'] ?? '',
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

class Booking {
  final String id;
  final String groomName;
  final String groomJaati;
  final String brideName;
  final String brideJaati;
  final String contact1;
  final String contact2;
  final String address;
  final Hall hall;
  final double? hallPriceOverride;
  final double hallDiscount;
  final double hallCharge; 
  final DateTime eventDate;
  final TimeOfDay? startTime; // Can be used as Muhurtham Time
  final TimeOfDay? endTime;
  final String? lagna;
  final BookingStatus status;
  final double advancePaid;
  final double totalAmount;
  final double subtotal; 
  final double? menuRateOverride;
  final double cateringDiscount;
  final int guestCount;
  final int cateringTier;
  final bool utaRequired;
  final double cateringTotal;
  final double utaAmount;
  final List<String> cateringItems;

  // Extra Services
  final bool addVadya;
  final double vadyaCharge;
  final bool addPalav;
  final bool addPoori;
  final bool addIceCream;
  final bool addWater;
  final bool addCleaning;
  final double cleaningCharge;

  // Additional Catering Services
  final bool addPreviousDayHall;
  final double previousDayHallAmount;
  final bool addBeligeTindi;
  final int beligeTindiGuestCount;
  final String beligeTindiItems;
  final double beligeTindiAmount;
  final bool addSanjeTindi;
  final int sanjeTindiGuestCount;
  final String sanjeTindiItems;
  final double sanjeTindiAmount;
  final bool addRatriUta;
  final int ratriUtaGuestCount;
  final String ratriUtaItems;
  final double ratriUtaAmount;

  // Extra Purohitaru
  final bool extraPurohitaruEnabled;
  final double extraPurohitaruAmount;
  final double extraPurohitaru;

  // Drink / Sharbat
  final bool drinkEnabled;
  final String drinkName;
  final int drinkMemberCount;
  final double drinkTotalAmount;

  final List<BookingCustomExtra> customExtras;
  final List<BookingSavedExtra> savedExtras; 

  final List<PaymentEntry> paymentHistory;
  final List<String> logs;
  final String? notes;

  // Marriage Certificate Fields
  final String? groomDob;
  final String? groomGender;
  final String? groomFatherName;
  final String? groomAddress;
  final String? groomAadhaar; // Full encrypted Aadhaar
  final bool groomVerified;

  final String? brideDob;
  final String? brideGender;
  final String? brideFatherName;
  final String? brideAddress;
  final String? brideAadhaar; // Full encrypted Aadhaar
  final bool brideVerified;

  final String? invitationPhotoPath;
  final bool certificateIssued;
  final DateTime? certificateIssuedAt;
  final String? certificatePdfPath;
  final String? collectedByMobile;

  // Reissue fields
  final bool certificateReissued;
  final String? reissueReason;
  final DateTime? reissueDate;

  // Final Event Day fields
  final int? finalGuestCount;
  final double additionalGuestsCharge;

  Booking({
    required this.id,
    required this.groomName,
    required this.groomJaati,
    required this.brideName,
    required this.brideJaati,
    required this.contact1,
    required this.contact2,
    required this.address,
    required this.hall,
    this.hallPriceOverride,
    this.hallDiscount = 0,
    this.hallCharge = 0,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.lagna,
    required this.status,
    this.advancePaid = 0,
    this.totalAmount = 0,
    this.subtotal = 0,
    this.menuRateOverride,
    this.cateringDiscount = 0,
    this.guestCount = 150,
    this.cateringTier = 2,
    this.utaRequired = false,
    this.cateringTotal = 0,
    this.utaAmount = 0,
    this.cateringItems = const [],
    this.addVadya = false,
    this.vadyaCharge = 0,
    this.addPalav = false,
    this.addPoori = false,
    this.addIceCream = false,
    this.addWater = false,
    this.addCleaning = true,
    this.cleaningCharge = 0,
    this.addPreviousDayHall = false,
    this.previousDayHallAmount = 0,
    this.addBeligeTindi = false,
    this.beligeTindiGuestCount = 0,
    this.beligeTindiItems = '',
    this.beligeTindiAmount = 0,
    this.addSanjeTindi = false,
    this.sanjeTindiGuestCount = 0,
    this.sanjeTindiItems = '',
    this.sanjeTindiAmount = 0,
    this.addRatriUta = false,
    this.ratriUtaGuestCount = 0,
    this.ratriUtaItems = '',
    this.ratriUtaAmount = 0,
    this.extraPurohitaruEnabled = false,
    this.extraPurohitaruAmount = 7000,
    this.extraPurohitaru = 0,
    this.drinkEnabled = false,
    this.drinkName = 'ಶರಬತ್',
    this.drinkMemberCount = 0,
    this.drinkTotalAmount = 0,
    this.customExtras = const [],
    this.savedExtras = const [],
    this.paymentHistory = const [],
    this.logs = const [],
    this.notes,

    this.groomDob,
    this.groomGender,
    this.groomFatherName,
    this.groomAddress,
    this.groomAadhaar,
    this.groomVerified = false,
    this.brideDob,
    this.brideGender,
    this.brideFatherName,
    this.brideAddress,
    this.brideAadhaar,
    this.brideVerified = false,
    this.invitationPhotoPath,
    this.certificateIssued = false,
    this.certificateIssuedAt,
    this.certificatePdfPath,
    this.collectedByMobile,
    this.certificateReissued = false,
    this.reissueReason,
    this.reissueDate,

    this.finalGuestCount,
    this.additionalGuestsCharge = 0,
  });

  String get displayGroomName => 'Chi. $groomName';

  String get displayBrideName => 'Chi.Sou. $brideName';

  Booking copyWith({
    String? id,
    String? groomName,
    String? groomJaati,
    String? brideName,
    String? brideJaati,
    String? contact1,
    String? contact2,
    String? address,
    Hall? hall,
    double? hallPriceOverride,
    double? hallDiscount,
    double? hallCharge,
    DateTime? eventDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? lagna,
    BookingStatus? status,
    double? advancePaid,
    double? totalAmount,
    double? subtotal,
    double? menuRateOverride,
    double? cateringDiscount,
    int? guestCount,
    int? cateringTier,
    bool? utaRequired,
    double? cateringTotal,
    double? utaAmount,
    List<String>? cateringItems,
    bool? addVadya,
    double? vadyaCharge,
    bool? addPalav,
    bool? addPoori,
    bool? addIceCream,
    bool? addWater,
    bool? addCleaning,
    double? cleaningCharge,
    bool? addPreviousDayHall,
    double? previousDayHallAmount,
    bool? addBeligeTindi,
    int? beligeTindiGuestCount,
    String? beligeTindiItems,
    double? beligeTindiAmount,
    bool? addSanjeTindi,
    int? sanjeTindiGuestCount,
    String? sanjeTindiItems,
    double? sanjeTindiAmount,
    bool? addRatriUta,
    int? ratriUtaGuestCount,
    String? ratriUtaItems,
    double? ratriUtaAmount,
    bool? extraPurohitaruEnabled,
    double? extraPurohitaruAmount,
    double? extraPurohitar,
    bool? drinkEnabled,
    String? drinkName,
    int? drinkMemberCount,
    double? drinkTotalAmount,
    List<BookingCustomExtra>? customExtras,
    List<BookingSavedExtra>? savedExtras,
    List<PaymentEntry>? paymentHistory,
    List<String>? logs,
    String? notes,

    String? groomDob,
    String? groomGender,
    String? groomFatherName,
    String? groomAddress,
    String? groomAadhaar,
    bool? groomVerified,
    String? brideDob,
    String? brideGender,
    String? brideFatherName,
    String? brideAddress,
    String? brideAadhaar,
    bool? brideVerified,
    String? invitationPhotoPath,
    bool? certificateIssued,
    DateTime? certificateIssuedAt,
    String? certificatePdfPath,
    String? collectedByMobile,
    bool? certificateReissued,
    String? reissueReason,
    DateTime? reissueDate,

    int? finalGuestCount,
    double? additionalGuestsCharge,
  }) {
    return Booking(
      id: id ?? this.id,
      groomName: groomName ?? this.groomName,
      groomJaati: groomJaati ?? this.groomJaati,
      brideName: brideName ?? this.brideName,
      brideJaati: brideJaati ?? this.brideJaati,
      contact1: contact1 ?? this.contact1,
      contact2: contact2 ?? this.contact2,
      address: address ?? this.address,
      hall: hall ?? this.hall,
      hallPriceOverride: hallPriceOverride ?? this.hallPriceOverride,
      hallDiscount: hallDiscount ?? this.hallDiscount,
      hallCharge: hallCharge ?? this.hallCharge,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lagna: lagna ?? this.lagna,
      status: status ?? this.status,
      advancePaid: advancePaid ?? this.advancePaid,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      menuRateOverride: menuRateOverride ?? this.menuRateOverride,
      cateringDiscount: cateringDiscount ?? this.cateringDiscount,
      guestCount: guestCount ?? this.guestCount,
      cateringTier: cateringTier ?? this.cateringTier,
      utaRequired: utaRequired ?? this.utaRequired,
      cateringTotal: cateringTotal ?? this.cateringTotal,
      utaAmount: utaAmount ?? this.utaAmount,
      cateringItems: cateringItems ?? this.cateringItems,
      addVadya: addVadya ?? this.addVadya,
      vadyaCharge: vadyaCharge ?? this.vadyaCharge,
      addPalav: addPalav ?? this.addPalav,
      addPoori: addPoori ?? this.addPoori,
      addIceCream: addIceCream ?? this.addIceCream,
      addWater: addWater ?? this.addWater,
      addCleaning: addCleaning ?? this.addCleaning,
      cleaningCharge: cleaningCharge ?? this.cleaningCharge,
      addPreviousDayHall: addPreviousDayHall ?? this.addPreviousDayHall,
      previousDayHallAmount: previousDayHallAmount ??
          this.previousDayHallAmount,
      addBeligeTindi: addBeligeTindi ?? this.addBeligeTindi,
      beligeTindiGuestCount: beligeTindiGuestCount ??
          this.beligeTindiGuestCount,
      beligeTindiItems: beligeTindiItems ?? this.beligeTindiItems,
      beligeTindiAmount: beligeTindiAmount ?? this.beligeTindiAmount,
      addSanjeTindi: addSanjeTindi ?? this.addSanjeTindi,
      sanjeTindiGuestCount: sanjeTindiGuestCount ?? this.sanjeTindiGuestCount,
      sanjeTindiItems: sanjeTindiItems ?? this.sanjeTindiItems,
      sanjeTindiAmount: sanjeTindiAmount ?? this.sanjeTindiAmount,
      addRatriUta: addRatriUta ?? this.addRatriUta,
      ratriUtaGuestCount: ratriUtaGuestCount ?? this.ratriUtaGuestCount,
      ratriUtaItems: ratriUtaItems ?? this.ratriUtaItems,
      ratriUtaAmount: ratriUtaAmount ?? this.ratriUtaAmount,
      extraPurohitaruEnabled: extraPurohitaruEnabled ??
          this.extraPurohitaruEnabled,
      extraPurohitaruAmount: extraPurohitaruAmount ??
          this.extraPurohitaruAmount,
      extraPurohitaru: extraPurohitar ?? this.extraPurohitaru,
      drinkEnabled: drinkEnabled ?? this.drinkEnabled,
      drinkName: drinkName ?? this.drinkName,
      drinkMemberCount: drinkMemberCount ?? this.drinkMemberCount,
      drinkTotalAmount: drinkTotalAmount ?? this.drinkTotalAmount,
      customExtras: customExtras ?? this.customExtras,
      savedExtras: savedExtras ?? this.savedExtras,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      logs: logs ?? this.logs,
      notes: notes ?? this.notes,

      groomDob: groomDob ?? this.groomDob,
      groomGender: groomGender ?? this.groomGender,
      groomFatherName: groomFatherName ?? this.groomFatherName,
      groomAddress: groomAddress ?? this.groomAddress,
      groomAadhaar: groomAadhaar ?? this.groomAadhaar,
      groomVerified: groomVerified ?? this.groomVerified,
      brideDob: brideDob ?? this.brideDob,
      brideGender: brideGender ?? this.brideGender,
      brideFatherName: brideFatherName ?? this.brideFatherName,
      brideAddress: brideAddress ?? this.brideAddress,
      brideAadhaar: brideAadhaar ?? this.brideAadhaar,
      brideVerified: brideVerified ?? this.brideVerified,
      invitationPhotoPath: invitationPhotoPath ?? this.invitationPhotoPath,
      certificateIssued: certificateIssued ?? this.certificateIssued,
      certificateIssuedAt: certificateIssuedAt ?? this.certificateIssuedAt,
      certificatePdfPath: certificatePdfPath ?? this.certificatePdfPath,
      collectedByMobile: collectedByMobile ?? this.collectedByMobile,
      certificateReissued: certificateReissued ?? this.certificateReissued,
      reissueReason: reissueReason ?? this.reissueReason,
      reissueDate: reissueDate ?? this.reissueDate,

      finalGuestCount: finalGuestCount ?? this.finalGuestCount,
      additionalGuestsCharge: additionalGuestsCharge ?? this.additionalGuestsCharge,
    );
  }

  Map<String, dynamic> toMap() {
    String? timeToString(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour}:${time.minute}';
    }

    return {
      'groomName': groomName,
      'groomJaati': groomJaati,
      'brideName': brideName,
      'brideJaati': brideJaati,
      'contact1': contact1,
      'contact2': contact2,
      'address': address,
      'hall': hall.toMap(),
      'hallPriceOverride': hallPriceOverride,
      'hallDiscount': hallDiscount,
      'hallCharge': hallCharge,
      'eventDate': Timestamp.fromDate(eventDate),
      'startTime': timeToString(startTime),
      'endTime': timeToString(endTime),
      'lagna': lagna,
      'status': status.name,
      'advancePaid': advancePaid,
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'menuRateOverride': menuRateOverride,
      'cateringDiscount': cateringDiscount,
      'guestCount': guestCount,
      'cateringTier': cateringTier,
      'utaRequired': utaRequired,
      'cateringTotal': cateringTotal,
      'utaAmount': utaAmount,
      'cateringItems': cateringItems,
      'addVadya': addVadya,
      'vadyaCharge': vadyaCharge,
      'addPalav': addPalav,
      'addPoori': addPoori,
      'addIceCream': addIceCream,
      'addWater': addWater,
      'addCleaning': addCleaning,
      'cleaningCharge': cleaningCharge,
      'addPreviousDayHall': addPreviousDayHall,
      'previousDayHallAmount': previousDayHallAmount,
      'addBeligeTindi': addBeligeTindi,
      'beligeTindiGuestCount': beligeTindiGuestCount,
      'beligeTindiItems': beligeTindiItems,
      'beligeTindiAmount': beligeTindiAmount,
      'addSanjeTindi': addSanjeTindi,
      'sanjeTindiGuestCount': sanjeTindiGuestCount,
      'sanjeTindiItems': sanjeTindiItems,
      'sanjeTindiAmount': sanjeTindiAmount,
      'addRatriUta': addRatriUta,
      'ratriUtaGuestCount': ratriUtaGuestCount,
      'ratriUtaItems': ratriUtaItems,
      'ratriUtaAmount': ratriUtaAmount,
      'extraPurohitaruEnabled': extraPurohitaruEnabled,
      'extraPurohitaruAmount': extraPurohitaruAmount,
      'extraPurohitaru': extraPurohitaru,
      'drinkEnabled': drinkEnabled,
      'drinkName': drinkName,
      'drinkMemberCount': drinkMemberCount,
      'drinkTotalAmount': drinkTotalAmount,
      'customExtras': customExtras.map((e) => e.toMap()).toList(),
      'savedExtras': savedExtras.map((e) => e.toMap()).toList(),
      'paymentHistory': paymentHistory.map((p) => p.toMap()).toList(),
      'logs': logs,
      'notes': notes,
      'groomDob': groomDob,
      'groomGender': groomGender,
      'groomFatherName': groomFatherName,
      'groomAddress': groomAddress,
      'groomAadhaar': groomAadhaar,
      'groomVerified': groomVerified,
      'brideDob': brideDob,
      'brideGender': brideGender,
      'brideFatherName': brideFatherName,
      'brideAddress': brideAddress,
      'brideAadhaar': brideAadhaar,
      'brideVerified': brideVerified,
      'invitationPhotoPath': invitationPhotoPath,
      'certificateIssued': certificateIssued,
      'certificateIssuedAt': certificateIssuedAt != null ? Timestamp.fromDate(
          certificateIssuedAt!) : null,
      'certificatePdfPath': certificatePdfPath,
      'collectedByMobile': collectedByMobile,
      'certificateReissued': certificateReissued,
      'reissueReason': reissueReason,
      'reissueDate': reissueDate != null
          ? Timestamp.fromDate(reissueDate!)
          : null,
      'finalGuestCount': finalGuestCount,
      'additionalGuestsCharge': additionalGuestsCharge,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    TimeOfDay? parseTime(dynamic value) {
      if (value == null) return null;

      final String s = value.toString().trim();
      if (s.isEmpty) return null;

      final List<String> parts = s.split(':');
      if (parts.length < 2) return null;

      final int? hour = int.tryParse(parts[0]);
      final int? minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    }

    Hall parseHall(dynamic hallData) {
      if (hallData is Map) {
        final Map<String, dynamic> hallMap = Map<String, dynamic>.from(hallData);
        final String hallId = hallMap['id']?.toString() ?? '';
        
        if (hallMap['name']?.toString() == hallId || hallMap['name']?.toString() == '1' || hallMap['name']?.toString() == '2') {
           final resolved = Hall.lookup(hallId);
           if (resolved != null) return resolved;
        }

        return Hall.fromMap(
          hallMap,
          hallId,
        );
      }

      final String rawValue = hallData?.toString() ?? '';
      final resolvedHall = Hall.lookup(rawValue);
      if (resolvedHall != null) return resolvedHall;

      return Hall(
        id: rawValue,
        name: (rawValue == '1' || rawValue == '2') ? 'Unknown Hall' : (rawValue.isEmpty ? 'Unknown Hall' : rawValue),
        location: '',
        capacity: 0,
        packageRate: 0.0,
        cleaningCharge: 0.0,
        photoPaths: const [],
        facilities: const [],
        isActive: true,
      );
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      }

      return <String>[];
    }

    List<PaymentEntry> parsePaymentHistory(dynamic value) {
      if (value is! List) {
        return <PaymentEntry>[];
      }

      return value
          .whereType<Map>()
          .map(
            (item) =>
            PaymentEntry.fromMap(
              Map<String, dynamic>.from(item),
            ),
      )
          .toList();
    }

    List<BookingCustomExtra> parseCustomExtras(dynamic value) {
      if (value is! List) {
        return <BookingCustomExtra>[];
      }

      return value
          .whereType<Map>()
          .map(
            (item) =>
            BookingCustomExtra.fromMap(
              Map<String, dynamic>.from(item),
            ),
      )
          .toList();
    }

    List<BookingSavedExtra> parseSavedExtras(dynamic value) {
      if (value is! List) {
        return <BookingSavedExtra>[];
      }

      return value
          .whereType<Map>()
          .map(
            (item) =>
            BookingSavedExtra.fromMap(
              Map<String, dynamic>.from(item),
            ),
      )
          .toList();
    }

    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return null;
    }

    double parseDouble(dynamic value, [
      double defaultValue = 0.0,
    ]) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
        value?.toString().trim() ?? '',
      ) ??
          defaultValue;
    }

    int parseInt(dynamic value, [
      int defaultValue = 0,
    ]) {
      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(
        value?.toString().trim() ?? '',
      ) ??
          defaultValue;
    }

    bool parseBool(dynamic value, [
      bool defaultValue = false,
    ]) {
      if (value is bool) {
        return value;
      }

      if (value is String) {
        final String normalized = value.toLowerCase().trim();

        if (normalized == 'true' || normalized == '1') {
          return true;
        }

        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }

      if (value is num) {
        return value != 0;
      }

      return defaultValue;
    }

    return Booking(
      id: id,
      groomName: map['groomName']?.toString() ?? '',
      groomJaati: map['groomJaati']?.toString() ?? '',
      brideName: map['brideName']?.toString() ?? '',
      brideJaati: map['brideJaati']?.toString() ?? '',
      contact1: map['contact1']?.toString() ?? '',
      contact2: map['contact2']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      hall: parseHall(map['hall']),
      hallPriceOverride: map['hallPriceOverride'] == null
          ? null
          : parseDouble(map['hallPriceOverride']),
      hallDiscount: parseDouble(map['hallDiscount']),
      hallCharge: parseDouble(map['hallCharge']),
      eventDate:
      parseTimestamp(map['eventDate']) ?? DateTime.now(),
      startTime: parseTime(map['startTime']),
      endTime: parseTime(map['endTime']),
      lagna: map['lagna']?.toString(),
      status: BookingStatus.values.firstWhere(
            (e) =>
        e.name == (
            map['status']?.toString() ?? 'pending'
        ),
        orElse: () => BookingStatus.pending,
      ),
      advancePaid: parseDouble(map['advancePaid']),
      totalAmount: parseDouble(map['totalAmount']),
      subtotal: parseDouble(map['subtotal']),
      menuRateOverride: map['menuRateOverride'] == null
          ? null
          : parseDouble(map['menuRateOverride']),
      cateringDiscount: parseDouble(map['cateringDiscount']),
      guestCount: parseInt(
        map['guestCount'],
        150,
      ),
      cateringTier: parseInt(
        map['cateringTier'],
        2,
      ),
      utaRequired: parseBool(
        map['utaRequired'],
      ),
      cateringTotal: parseDouble(
        map['cateringTotal'],
      ),
      utaAmount: parseDouble(
        map['utaAmount'],
      ),
      cateringItems: parseStringList(
        map['cateringItems'],
      ),
      addVadya: parseBool(
        map['addVadya'],
      ),
      vadyaCharge: parseDouble(
        map['vadyaCharge'],
      ),
      addPalav: parseBool(
        map['addPalav'],
      ),
      addPoori: parseBool(
        map['addPoori'],
      ),
      addIceCream: parseBool(
        map['addIceCream'],
      ),
      addWater: parseBool(
        map['addWater'],
      ),
      addCleaning: parseBool(
        map['addCleaning'],
        true,
      ),
      cleaningCharge: parseDouble(
        map['cleaningCharge'],
      ),
      addPreviousDayHall: parseBool(
        map['addPreviousDayHall'],
      ),
      previousDayHallAmount: parseDouble(
        map['previousDayHallAmount'],
      ),
      addBeligeTindi: parseBool(
        map['addBeligeTindi'],
      ),
      beligeTindiGuestCount: parseInt(
        map['beligeTindiGuestCount'],
      ),
      beligeTindiItems:
      map['beligeTindiItems']?.toString() ?? '',
      beligeTindiAmount: parseDouble(
        map['beligeTindiAmount'],
      ),
      addSanjeTindi: parseBool(
        map['addSanjeTindi'],
      ),
      sanjeTindiGuestCount: parseInt(
        map['sanjeTindiGuestCount'],
      ),
      sanjeTindiItems:
      map['sanjeTindiItems']?.toString() ?? '',
      sanjeTindiAmount: parseDouble(
        map['sanjeTindiAmount'],
      ),
      addRatriUta: parseBool(
        map['addRatriUta'],
      ),
      ratriUtaGuestCount: parseInt(
        map['ratriUtaGuestCount'],
      ),
      ratriUtaItems:
      map['ratriUtaItems']?.toString() ?? '',
      ratriUtaAmount: parseDouble(
        map['ratriUtaAmount'],
      ),
      extraPurohitaruEnabled: parseBool(
        map['extraPurohitaruEnabled'],
      ),
      extraPurohitaruAmount: parseDouble(
        map['extraPurohitaruAmount'],
        7000.0,
      ),
      extraPurohitaru: parseDouble(
        map['extraPurohitaru'],
      ),
      drinkEnabled: parseBool(
        map['drinkEnabled'],
      ),
      drinkName:
      map['drinkName']?.toString() ?? 'ಶರಬತ್',
      drinkMemberCount: parseInt(
        map['drinkMemberCount'],
      ),
      drinkTotalAmount: parseDouble(
        map['drinkTotalAmount'],
      ),
      customExtras: parseCustomExtras(
        map['customExtras'],
      ),
      savedExtras: parseSavedExtras(
        map['savedExtras'],
      ),
      paymentHistory: parsePaymentHistory(
        map['paymentHistory'],
      ),
      logs: parseStringList(
        map['logs'],
      ),
      notes: map['notes']?.toString(),
      groomDob: map['groomDob']?.toString(),
      groomGender:
      map['groomGender']?.toString(),
      groomFatherName:
      map['groomFatherName']?.toString(),
      groomAddress:
      map['groomAddress']?.toString(),
      groomAadhaar:
      map['groomAadhaar']?.toString(),
      groomVerified: parseBool(
        map['groomVerified'],
      ),
      brideDob:
      map['brideDob']?.toString(),
      brideGender:
      map['brideGender']?.toString(),
      brideFatherName:
      map['brideFatherName']?.toString(),
      brideAddress:
      map['brideAddress']?.toString(),
      brideAadhaar:
      map['brideAadhaar']?.toString(),
      brideVerified: parseBool(
        map['brideVerified'],
      ),
      invitationPhotoPath:
      map['invitationPhotoPath']?.toString(),
      certificateIssued: parseBool(
        map['certificateIssued'],
      ),
      certificateIssuedAt: parseTimestamp(
        map['certificateIssuedAt'],
      ),
      certificatePdfPath:
      map['certificatePdfPath']?.toString(),
      collectedByMobile:
      map['collectedByMobile']?.toString(),
      certificateReissued: parseBool(
        map['certificateReissued'],
      ),
      reissueReason:
      map['reissueReason']?.toString(),
      reissueDate: parseTimestamp(
        map['reissueDate'],
      ),
      finalGuestCount: parseInt(map['finalGuestCount']),
      additionalGuestsCharge: parseDouble(map['additionalGuestsCharge']),
    );
  }
}
