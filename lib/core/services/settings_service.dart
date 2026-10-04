import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final String _docPath = 'settings/appSettings';

  // Temple / Business Info
  String businessName = 'Sri Kshetra Kollur Puranika Trust';
  String businessAddress = 'Kollur, Kundapura Taluk, Udupi District, Karnataka';
  String businessPhone = '9448843688';
  String businessEmail = 'office@puranikasada';

  // UPI & Payment
  String upiId = 'puranika@upi';
  String? upiQrImageUrl;

  // Logo & Branding
  String? logoImageUrl;

  // Receipt Footer & Terms
  String receiptFooter = 'Thank you for choosing Puranika Sadana. For queries, contact 9448843688.';
  String termsAndConditions = '1. Hall must be vacated within 2 hours after the event.\n2. Damages to hall property will be charged separately.';

  // Owner PIN for restricted actions
  String ownerPin = '1234';

  // Reminder Settings
  int firstReminderDays = 3;
  int finalReminderDays = 1;
  bool dailyBalanceReminders = true;
  bool pushNotificationsEnabled = true;

  // Catering Rates
  double cateringTier1Rate = 180;
  double cateringTier2Rate = 210;
  double cateringTier3Rate = 240;

  bool isInitialized = false;

  Future<void> init() async {
    try {
      final doc = await _db.doc(_docPath).get();
      if (doc.exists) {
        final data = doc.data()!;
        businessName = data['templeName'] ?? businessName;
        businessAddress = data['templeAddress'] ?? businessAddress;
        businessPhone = data['templePhone'] ?? businessPhone;
        businessEmail = data['templeEmail'] ?? businessEmail;

        upiId = data['upiId'] ?? upiId;
        upiQrImageUrl = data['upiQrImageUrl'];
        logoImageUrl = data['logoImageUrl'];

        receiptFooter = data['receiptFooterNote'] ?? receiptFooter;
        termsAndConditions = data['termsAndConditions'] ?? termsAndConditions;
        
        ownerPin = data['ownerPin'] ?? ownerPin;

        firstReminderDays = data['reminderFirstAlertDays'] ?? firstReminderDays;
        finalReminderDays = data['reminderFinalAlertDays'] ?? finalReminderDays;
        dailyBalanceReminders = data['dailyBalanceRemindersEnabled'] ?? dailyBalanceReminders;
        pushNotificationsEnabled = data['pushNotificationsEnabled'] ?? pushNotificationsEnabled;

        cateringTier1Rate = (data['cateringTier1Rate'] as num?)?.toDouble() ?? cateringTier1Rate;
        cateringTier2Rate = (data['cateringTier2Rate'] as num?)?.toDouble() ?? cateringTier2Rate;
        cateringTier3Rate = (data['cateringTier3Rate'] as num?)?.toDouble() ?? cateringTier3Rate;
      }
      isInitialized = true;
    } catch (e) {
      debugPrint('SettingsService initialization error: $e');
      isInitialized = true;
    }
  }

  Future<void> _update(Map<String, dynamic> data) async {
    await _db.doc(_docPath).set(data, SetOptions(merge: true));
  }

  Future<void> saveBusinessInfo(String name, String address, String phone, String email) async {
    businessName = name;
    businessAddress = address;
    businessPhone = phone;
    businessEmail = email;
    await _update({
      'templeName': name,
      'templeAddress': address,
      'templePhone': phone,
      'templeEmail': email,
    });
  }

  Future<void> saveUpiInfo(String id, String? imageUrl) async {
    upiId = id;
    if (imageUrl != null) upiQrImageUrl = imageUrl;
    await _update({
      'upiId': id,
      if (imageUrl != null) 'upiQrImageUrl': imageUrl,
    });
  }

  Future<void> saveLogo(String imageUrl) async {
    logoImageUrl = imageUrl;
    await _update({
      'logoImageUrl': imageUrl,
    });
  }

  Future<void> saveReceiptSettings(String footer, String terms) async {
    receiptFooter = footer;
    termsAndConditions = terms;
    await _update({
      'receiptFooterNote': footer,
      'termsAndConditions': terms,
    });
  }

  Future<void> saveOwnerPin(String pin) async {
    ownerPin = pin;
    await _update({
      'ownerPin': pin,
    });
  }

  Future<void> saveReminderSettings(int first, int last, bool daily, bool push) async {
    firstReminderDays = first;
    finalReminderDays = last;
    dailyBalanceReminders = daily;
    pushNotificationsEnabled = push;
    await _update({
      'reminderFirstAlertDays': first,
      'reminderFinalAlertDays': last,
      'dailyBalanceRemindersEnabled': daily,
      'pushNotificationsEnabled': push,
    });
  }

  Future<void> saveCateringPrices(double t1, double t2, double t3) async {
    cateringTier1Rate = t1;
    cateringTier2Rate = t2;
    cateringTier3Rate = t3;
    await _update({
      'cateringTier1Rate': t1,
      'cateringTier2Rate': t2,
      'cateringTier3Rate': t3,
    });
  }

  Future<String> uploadImage(File file, String destination) async {
    final ref = _storage.ref().child(destination);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
