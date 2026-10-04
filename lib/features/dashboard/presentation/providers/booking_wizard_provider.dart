import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/hall.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/booking_status.dart';

class CustomExtra {
  final String name;
  final double rate;
  final bool isFlat;

  CustomExtra({required this.name, required this.rate, this.isFlat = false});

  BookingCustomExtra toBookingExtra() => BookingCustomExtra(name: name, rate: rate, isFlat: isFlat);
  
  factory CustomExtra.fromBookingExtra(BookingCustomExtra extra) => 
    CustomExtra(name: extra.name, rate: extra.rate, isFlat: extra.isFlat);
}

class BookingWizardState {
  final String groomName;
  final String groomJaati;
  final String brideName;
  final String brideJaati;
  final String contact1;
  final String contact2;
  final String address;
  
  final Hall? selectedHall;
  final double? hallPriceOverride;
  final double hallDiscount;
  
  final bool addVadya;
  final double vadyaCharge;
  
  final DateTime? eventDate;
  final String? lagna;
  final TimeOfDay? muhurthamTime;
  final int guestCount;

  // Extra Purohitaru
  final bool extraPurohitaruEnabled;
  final double extraPurohitaruAmount;
  final double extraPurohitaru;

  final bool utaRequired;
  final int? selectedMenuTier;
  final double? menuRateOverride;
  final double cateringDiscount;
  final bool addPalav;
  final bool addPoori;
  final bool addIceCream;
  final bool addWater;
  final bool addCleaning;
  final double cleaningCharge;
  final List<CustomExtra> customExtras;
  final double cateringTotal; // Manual Entry
  final double utaAmount; // Calculated Amount
  final List<String> cateringItems;

  // Additional Services
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

  // Drink / Sharbat
  final bool drinkEnabled;
  final String drinkName;
  final int drinkMemberCount;
  final double drinkTotalAmount;

  final double advanceAmount;
  final double totalAmount; 
  final String paymentMethod; 
  final String advanceStatus;
  final List<PaymentEntry> paymentHistory;

  // Edit Mode
  final bool isEditMode;
  final String? editingBookingId;

  // Final Event Day fields
  final int? finalGuestCount;
  final double additionalGuestsCharge;

  // Persistence fields for Breakdown
  final double hallCharge;
  final double subtotal;
  final List<BookingSavedExtra> savedExtras;

  final int maxStepReached;

  BookingWizardState({
    this.groomName = '',
    this.groomJaati = '',
    this.brideName = '',
    this.brideJaati = '',
    this.contact1 = '',
    this.contact2 = '',
    this.address = '',
    this.selectedHall,
    this.hallPriceOverride,
    this.hallDiscount = 0,
    this.addVadya = false,
    this.vadyaCharge = 0,
    this.eventDate,
    this.lagna,
    this.muhurthamTime,
    this.guestCount = 0,
    this.extraPurohitaruEnabled = false,
    this.extraPurohitaruAmount = 7000,
    this.extraPurohitaru = 0,
    this.utaRequired = false,
    this.selectedMenuTier,
    this.menuRateOverride,
    this.cateringDiscount = 0,
    this.addPalav = false,
    this.addPoori = false,
    this.addIceCream = false,
    this.addWater = false,
    this.addCleaning = false,
    this.cleaningCharge = 0,
    this.customExtras = const [],
    this.cateringTotal = 0,
    this.utaAmount = 0,
    this.cateringItems = const [
      'ಉಪ್ಪು', 'ಉಪ್ಪಿನಕಾಯಿ', 'ಕೋಸಂಬರಿ', 'ಚಟ್ನಿ', '2 ಪಲ್ಯ', 'ಹಪ್ಪಳ', 'ಅನ್ನ', 'ಸಾರು', 'ಹುಳಿ', '1 ಲಾಡು', 'ಪೋಡಿ', 'ಪಾಯಸ', 'ಅನ್ನ & ಮಜ್ಜಿಗೆ'
    ],
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
    this.drinkEnabled = false,
    this.drinkName = 'ಶರಬತ್',
    this.drinkMemberCount = 0,
    this.drinkTotalAmount = 0,
    this.advanceAmount = 0,
    this.totalAmount = 0,
    this.paymentMethod = 'UPI',
    this.advanceStatus = 'Pending',
    this.paymentHistory = const [],
    this.isEditMode = false,
    this.editingBookingId,
    this.finalGuestCount,
    this.additionalGuestsCharge = 0,
    this.hallCharge = 0,
    this.subtotal = 0,
    this.savedExtras = const [],
    this.maxStepReached = 1,
  });

  factory BookingWizardState.fromBooking(Booking booking) {
    return BookingWizardState(
      isEditMode: true,
      editingBookingId: booking.id,
      groomName: booking.groomName,
      groomJaati: booking.groomJaati,
      brideName: booking.brideName,
      brideJaati: booking.brideJaati,
      contact1: booking.contact1,
      contact2: booking.contact2,
      address: booking.address,
      selectedHall: booking.hall,
      hallPriceOverride: booking.hallPriceOverride,
      hallDiscount: booking.hallDiscount,
      hallCharge: booking.hallCharge,
      addVadya: booking.addVadya,
      vadyaCharge: booking.vadyaCharge,
      eventDate: booking.eventDate,
      lagna: booking.lagna,
      muhurthamTime: booking.startTime,
      guestCount: booking.guestCount,
      extraPurohitaruEnabled: booking.extraPurohitaruEnabled,
      extraPurohitaruAmount: booking.extraPurohitaruAmount,
      extraPurohitaru: booking.extraPurohitaru,
      utaRequired: booking.utaRequired,
      selectedMenuTier: booking.cateringTier,
      menuRateOverride: booking.menuRateOverride,
      cateringDiscount: booking.cateringDiscount,
      addPalav: booking.addPalav,
      addPoori: booking.addPoori,
      addIceCream: booking.addIceCream,
      addWater: booking.addWater,
      addCleaning: booking.addCleaning,
      cleaningCharge: booking.cleaningCharge,
      cateringTotal: booking.cateringTotal,
      utaAmount: booking.utaAmount,
      cateringItems: booking.cateringItems,
      addPreviousDayHall: booking.addPreviousDayHall,
      previousDayHallAmount: booking.previousDayHallAmount,
      addBeligeTindi: booking.addBeligeTindi,
      beligeTindiGuestCount: booking.beligeTindiGuestCount,
      beligeTindiItems: booking.beligeTindiItems,
      beligeTindiAmount: booking.beligeTindiAmount,
      addSanjeTindi: booking.addSanjeTindi,
      sanjeTindiGuestCount: booking.sanjeTindiGuestCount,
      sanjeTindiItems: booking.sanjeTindiItems,
      sanjeTindiAmount: booking.sanjeTindiAmount,
      addRatriUta: booking.addRatriUta,
      ratriUtaGuestCount: booking.ratriUtaGuestCount,
      ratriUtaItems: booking.ratriUtaItems,
      ratriUtaAmount: booking.ratriUtaAmount,
      drinkEnabled: booking.drinkEnabled,
      drinkName: booking.drinkName,
      drinkMemberCount: booking.drinkMemberCount,
      drinkTotalAmount: booking.drinkTotalAmount,
      customExtras: booking.customExtras.map((e) => CustomExtra.fromBookingExtra(e)).toList(),
      savedExtras: booking.savedExtras,
      advanceAmount: booking.advancePaid,
      totalAmount: booking.totalAmount,
      subtotal: booking.subtotal,
      paymentHistory: booking.paymentHistory,
      paymentMethod: booking.paymentHistory.isNotEmpty ? booking.paymentHistory.last.method : 'UPI',
      advanceStatus: booking.advancePaid > 0 ? 'Paid' : 'Pending',
      finalGuestCount: booking.finalGuestCount,
      additionalGuestsCharge: booking.additionalGuestsCharge,
      maxStepReached: 6,
    );
  }

  BookingWizardState copyWith({
    String? groomName,
    String? groomJaati,
    String? brideName,
    String? brideJaati,
    String? contact1,
    String? contact2,
    String? address,
    Hall? selectedHall,
    double? hallPriceOverride,
    double? hallDiscount,
    bool? addVadya,
    double? vadyaCharge,
    DateTime? eventDate,
    String? lagna,
    TimeOfDay? muhurthamTime,
    int? guestCount,
    bool? extraPurohitaruEnabled,
    double? extraPurohitaruAmount,
    double? extraPurohitaru,
    bool? utaRequired,
    int? selectedMenuTier,
    double? menuRateOverride,
    double? cateringDiscount,
    bool? addPalav,
    bool? addPoori,
    bool? addIceCream,
    bool? addWater,
    bool? addCleaning,
    double? cleaningCharge,
    List<CustomExtra>? customExtras,
    double? cateringTotal,
    double? utaAmount,
    List<String>? cateringItems,
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
    bool? drinkEnabled,
    String? drinkName,
    int? drinkMemberCount,
    double? drinkTotalAmount,
    double? advanceAmount,
    double? totalAmount,
    String? paymentMethod,
    String? advanceStatus,
    List<PaymentEntry>? paymentHistory,
    bool? isEditMode,
    String? editingBookingId,
    int? finalGuestCount,
    double? additionalGuestsCharge,
    double? hallCharge,
    double? subtotal,
    List<BookingSavedExtra>? savedExtras,
    int? maxStepReached,
  }) {
    return BookingWizardState(
      groomName: groomName ?? this.groomName,
      groomJaati: groomJaati ?? this.groomJaati,
      brideName: brideName ?? this.brideName,
      brideJaati: brideJaati ?? this.brideJaati,
      contact1: contact1 ?? this.contact1,
      contact2: contact2 ?? this.contact2,
      address: address ?? this.address,
      selectedHall: selectedHall ?? this.selectedHall,
      hallPriceOverride: hallPriceOverride != null ? (hallPriceOverride == -1 ? null : hallPriceOverride) : this.hallPriceOverride,
      hallDiscount: hallDiscount ?? this.hallDiscount,
      addVadya: addVadya ?? this.addVadya,
      vadyaCharge: vadyaCharge ?? this.vadyaCharge,
      eventDate: eventDate ?? this.eventDate,
      lagna: lagna ?? this.lagna,
      muhurthamTime: muhurthamTime ?? this.muhurthamTime,
      guestCount: guestCount ?? this.guestCount,
      extraPurohitaruEnabled: extraPurohitaruEnabled ?? this.extraPurohitaruEnabled,
      extraPurohitaruAmount: extraPurohitaruAmount ?? this.extraPurohitaruAmount,
      extraPurohitaru: extraPurohitaru ?? this.extraPurohitaru,
      utaRequired: utaRequired ?? this.utaRequired,
      selectedMenuTier: selectedMenuTier ?? this.selectedMenuTier,
      menuRateOverride: menuRateOverride != null ? (menuRateOverride == -1 ? null : menuRateOverride) : this.menuRateOverride,
      cateringDiscount: cateringDiscount ?? this.cateringDiscount,
      addPalav: addPalav ?? this.addPalav,
      addPoori: addPoori ?? this.addPoori,
      addIceCream: addIceCream ?? this.addIceCream,
      addWater: addWater ?? this.addWater,
      addCleaning: addCleaning ?? this.addCleaning,
      cleaningCharge: cleaningCharge ?? this.cleaningCharge,
      customExtras: customExtras ?? this.customExtras,
      cateringTotal: cateringTotal ?? this.cateringTotal,
      utaAmount: utaAmount ?? this.utaAmount,
      cateringItems: cateringItems ?? this.cateringItems,
      addPreviousDayHall: addPreviousDayHall ?? this.addPreviousDayHall,
      previousDayHallAmount: previousDayHallAmount ?? this.previousDayHallAmount,
      addBeligeTindi: addBeligeTindi ?? this.addBeligeTindi,
      beligeTindiGuestCount: beligeTindiGuestCount ?? this.beligeTindiGuestCount,
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
      drinkEnabled: drinkEnabled ?? this.drinkEnabled,
      drinkName: drinkName ?? this.drinkName,
      drinkMemberCount: drinkMemberCount ?? this.drinkMemberCount,
      drinkTotalAmount: drinkTotalAmount ?? this.drinkTotalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      advanceStatus: advanceStatus ?? this.advanceStatus,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      isEditMode: isEditMode ?? this.isEditMode,
      editingBookingId: editingBookingId ?? this.editingBookingId,
      finalGuestCount: finalGuestCount ?? this.finalGuestCount,
      additionalGuestsCharge: additionalGuestsCharge ?? this.additionalGuestsCharge,
      hallCharge: hallCharge ?? this.hallCharge,
      subtotal: subtotal ?? this.subtotal,
      savedExtras: savedExtras ?? this.savedExtras,
      maxStepReached: maxStepReached ?? this.maxStepReached,
    );
  }
}

class BookingWizardNotifier extends StateNotifier<BookingWizardState> {
  BookingWizardNotifier() : super(BookingWizardState());

  void initFromBooking(Booking booking) {
    state = BookingWizardState.fromBooking(booking);
  }

  void setEditMode(bool isEdit, String? bookingId) {
    state = state.copyWith(isEditMode: isEdit, editingBookingId: bookingId);
  }

  void updateMaxStep(int step) {
    if (step > state.maxStepReached) {
      state = state.copyWith(maxStepReached: step);
    }
  }

  void updateGroomDetails(String name, String jaati) {
    state = state.copyWith(groomName: name, groomJaati: jaati);
  }

  void updateBrideDetails(String name, String jaati) {
    state = state.copyWith(brideName: name, brideJaati: jaati);
  }

  void updateContactInfo(String c1, String c2, String addr) {
    state = state.copyWith(contact1: c1, contact2: c2, address: addr);
  }

  void updateHallSelection(Hall hall, bool vadya, [double? vadyaAmt]) {
    state = state.copyWith(
      selectedHall: hall, 
      addVadya: vadya, 
      vadyaCharge: vadyaAmt ?? state.vadyaCharge,
    );
  }

  void updateHallPriceOverride(double? price) {
    state = state.copyWith(hallPriceOverride: price ?? -1);
  }

  void updateHallDiscount(double discount) {
    state = state.copyWith(hallDiscount: discount);
  }

  void updateCateringDiscount(double discount) {
    state = state.copyWith(cateringDiscount: discount);
  }

  void updateMuhurthamDetails({
    DateTime? date,
    String? lagna,
    TimeOfDay? time,
    int? guests,
    double? advance,
    bool? extraPurohitaruEnabled,
    double? extraPurohitaruAmount,
    double? extraPurohitaru,
  }) {
    state = state.copyWith(
      eventDate: date,
      lagna: lagna,
      muhurthamTime: time,
      guestCount: guests ?? 0,
      advanceAmount: advance,
      extraPurohitaruEnabled: extraPurohitaruEnabled,
      extraPurohitaruAmount: extraPurohitaruAmount,
      extraPurohitaru: extraPurohitaru,
    );
  }

  void updateMenuSelection({
    bool? utaRequired,
    int? tier,
    double? menuRateOverride,
    bool? palav,
    bool? poori,
    bool? iceCream,
    bool? water,
    bool? cleaning,
    double? cleaningAmt,
    List<CustomExtra>? custom,
    double? cateringTotal,
    double? utaAmount,
    List<String>? cateringItems,
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
    bool? drinkEnabled,
    String? drinkName,
    int? drinkMemberCount,
    double? drinkTotalAmount,
  }) {
    state = state.copyWith(
      utaRequired: utaRequired,
      selectedMenuTier: tier,
      menuRateOverride: menuRateOverride ?? (menuRateOverride == null ? null : -1),
      addPalav: palav,
      addPoori: poori,
      addIceCream: iceCream,
      addWater: water,
      addCleaning: cleaning,
      cleaningCharge: cleaningAmt,
      customExtras: custom,
      cateringTotal: cateringTotal,
      utaAmount: utaAmount,
      cateringItems: cateringItems,
      addPreviousDayHall: addPreviousDayHall,
      previousDayHallAmount: previousDayHallAmount,
      addBeligeTindi: addBeligeTindi,
      beligeTindiGuestCount: beligeTindiGuestCount,
      beligeTindiItems: beligeTindiItems,
      beligeTindiAmount: beligeTindiAmount,
      addSanjeTindi: addSanjeTindi,
      sanjeTindiGuestCount: sanjeTindiGuestCount,
      sanjeTindiItems: sanjeTindiItems,
      sanjeTindiAmount: sanjeTindiAmount,
      addRatriUta: addRatriUta,
      ratriUtaGuestCount: ratriUtaGuestCount,
      ratriUtaItems: ratriUtaItems,
      ratriUtaAmount: ratriUtaAmount,
      drinkEnabled: drinkEnabled,
      drinkName: drinkName,
      drinkMemberCount: drinkMemberCount,
      drinkTotalAmount: drinkTotalAmount,
    );
  }

  void updatePaymentDetails({
    double? advanceAmount,
    String? paymentMethod,
    String? advanceStatus,
    double? totalAmount,
    double? hallCharge,
    double? subtotal,
    List<BookingSavedExtra>? savedExtras,
    double? cateringTotal,
  }) {
    state = state.copyWith(
      advanceAmount: advanceAmount,
      paymentMethod: paymentMethod,
      advanceStatus: advanceStatus,
      totalAmount: totalAmount,
      hallCharge: hallCharge,
      subtotal: subtotal,
      savedExtras: savedExtras,
      cateringTotal: cateringTotal,
    );
  }

  void updateMenuRateOverride(double? rate) {
    state = state.copyWith(menuRateOverride: rate ?? -1);
  }

  void reset() {
    state = BookingWizardState();
  }
}

final bookingWizardProvider =
    StateNotifierProvider<BookingWizardNotifier, BookingWizardState>((ref) {
  return BookingWizardNotifier();
});
