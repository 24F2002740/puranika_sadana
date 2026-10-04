import 'package:shared_preferences/shared_preferences.dart';
import '../../features/dashboard/domain/models/hall.dart';
import '../../features/dashboard/domain/models/booking.dart';
import 'settings_service.dart';

class PricingService {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  final _settings = SettingsService();

  // Hall Packages (Fallback values for backward compatibility)
  double get smallHallPackagePrice => 20000;
  double get bigHallPackagePrice => 32000;

  // Vadya
  double _vadyaCharge = 6500;

  // Uta
  // Catering rates now come from SettingsService
  double get menu1Price => _settings.cateringTier1Rate;
  double get menu2Price => _settings.cateringTier2Rate;
  double get menu3Price => _settings.cateringTier3Rate;
  
  int _manualEntryThreshold = 150;

  // Menu Dish Lists
  List<String> _menu1Dishes = [
    'ಉಪ್ಪು', 'ಉಪ್ಪಿನಕಾಯಿ', 'ಕೋಸಂಬರಿ', 'ಚಟ್ನಿ', '2 ಪಲ್ಯ', 'ಹಪ್ಪಳ', 'ಅನ್ನ', 'ಸಾರು', 'ಹುಳಿ', '1 ಲಾಡು', 'ಪೋಡಿ', 'ಪಾಯಸ', 'ಅನ್ನ & ಮಜ್ಜಿಗೆ'
  ];
  List<String> _menu2Dishes = [
    'ಉಪ್ಪು', 'ಉಪ್ಪಿನಕಾಯಿ', 'ಕೋಸಂಬರಿ', 'ಚಟ್ನಿ', '2 ಪಲ್ಯ', 'ಚಿತ್ರಾನ್ನ', 'ಹಪ್ಪಳ', 'ಅನ್ನ', 'ಸಾರು', 'ಹುಳಿ', '1 ಲಾಡು', 'ಹೋಳಿಗೆ', 'ತುಪ್ಪ', 'ಪೋಡಿ', 'ಪಾಯಸ', 'ಅನ್ನ & ಮಜ್ಜಿಗೆ'
  ];
  List<String> _menu3Dishes = [
    'ಉಪ್ಪು', 'ಉಪ್ಪಿನಕಾಯಿ', '2 ಕೋಸಂಬರಿ', 'ಚಟ್ನಿ', '2 ಪಲ್ಯ', 'ಕಡಲೆಗಸಿ', 'ಚಿತ್ರಾನ್ನ', 'ಹಪ್ಪಳ', 'ಅನ್ನ', 'ತೊವೆ', 'ಸಾರು', 'ಹುಳಿ', 'ಮುದ್ದುಳಿ (ಅನಾನಸ್)', 'ತುಪ್ಪ', '1 ಲಾಡು', 'ಹೋಳಿಗೆ', 'ಮೆಣಸು ಬಜ್ಜಿ', 'ಪಾಯಸ', 'ಅನ್ನ ಮಜ್ಜಿಗೆ'
  ];

  // Add-ons
  double _palavSaladPrice = 35;
  double _pooriSaguPrice = 45;
  double _iceCreamPrice = 6;
  double _waterBottlePrice = 7;
  double _defaultCleaningCharge = 2500;
  double _defaultDrinkAmount = 7000;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _vadyaCharge = prefs.getDouble('vadya_charge') ?? 6500;
    
    _manualEntryThreshold = prefs.getInt('manual_entry_threshold') ?? 150;

    _menu1Dishes = prefs.getStringList('menu1_dishes') ?? _menu1Dishes;
    _menu2Dishes = prefs.getStringList('menu2_dishes') ?? _menu2Dishes;
    _menu3Dishes = prefs.getStringList('menu3_dishes') ?? _menu3Dishes;
    
    _palavSaladPrice = prefs.getDouble('palav_salad_price') ?? 35;
    _pooriSaguPrice = prefs.getDouble('poori_sagu_price') ?? 45;
    _iceCreamPrice = prefs.getDouble('ice_cream_price') ?? 6;
    _waterBottlePrice = prefs.getDouble('water_bottle_price') ?? 7;
    _defaultCleaningCharge = prefs.getDouble('default_cleaning_charge') ?? 2500;
    _defaultDrinkAmount = prefs.getDouble('default_drink_amount') ?? 7000;
  }

  // Getters
  double get vadyaCharge => _vadyaCharge;
  int get manualEntryThreshold => _manualEntryThreshold;

  List<String> get menu1Dishes => _menu1Dishes;
  List<String> get menu2Dishes => _menu2Dishes;
  List<String> get menu3Dishes => _menu3Dishes;

  List<String> getHallFeatures(Hall? hall) {
    return hall?.facilities ?? [];
  }

  double get palavSaladPrice => _palavSaladPrice;
  double get pooriSaguPrice => _pooriSaguPrice;
  double get iceCreamPrice => _iceCreamPrice;
  double get waterBottlePrice => _waterBottlePrice;
  double get defaultCleaningCharge => _defaultCleaningCharge;
  double get defaultDrinkAmount => _defaultDrinkAmount;

  Future<void> updateCateringPrices(double t1, double t2, double t3) async {
    await _settings.saveCateringPrices(t1, t2, t3);
  }

  /// Base calculation for catering (Base tier + addons). 
  /// Custom extras and folding are handled in the Booking Wizard logic.
  double calculateCateringTotal({
    required int guestCount,
    required int? menuTier,
    double? menuRateOverride,
    bool addPalav = false,
    bool addPoori = false,
    bool addIceCream = false,
    bool addWater = false,
  }) {
    if (menuTier == null && (menuRateOverride == null || menuRateOverride <= 0)) return 0;

    double menuRate = 0;
    if (menuRateOverride != null && menuRateOverride > 0) {
      menuRate = menuRateOverride;
    } else if (menuTier != null) {
      if (menuTier == 1) {
        menuRate = menu1Price;
      } else if (menuTier == 2) {
        menuRate = menu2Price;
      } else if (menuTier == 3) {
        menuRate = menu3Price;
      }
    }

    double total = menuRate * guestCount;

    if (addPalav) total += _palavSaladPrice * guestCount;
    if (addPoori) total += _pooriSaguPrice * guestCount;
    if (addIceCream) total += _iceCreamPrice * guestCount;
    if (addWater) total += _waterBottlePrice * guestCount;
    
    return total;
  }

  double calculateTotal({
    required Hall? hall,
    double? hallOverride,
    double hallDiscount = 0,
    bool addVadya = false,
    double vadyaChargeOverride = 0,
    double cateringManualTotal = 0,
    double utaAmount = 0,
    double cateringDiscount = 0,
    bool addCleaning = false,
    double cleaningCharge = 0,
    double previousDayHallAmount = 0,
    double beligeTindiAmount = 0,
    double sanjeTindiAmount = 0,
    double ratriUtaAmount = 0,
    bool extraPurohitaruEnabled = false,
    double extraPurohitaruAmount = 0,
    double drinkTotalAmount = 0,
    double additionalGuestsCharge = 0,
  }) {
    double total = 0;
    if (hall != null) {
      total = (hallOverride ?? hall.packageRate) - hallDiscount;
    }
    
    if (addVadya) {
      total += vadyaChargeOverride > 0 ? vadyaChargeOverride : vadyaCharge;
    }
    
    // Catering folded amount - discount
    total += (cateringManualTotal > 0 ? cateringManualTotal : utaAmount) - cateringDiscount;

    if (addCleaning) total += cleaningCharge;
    
    total += previousDayHallAmount;
    total += beligeTindiAmount;
    total += sanjeTindiAmount;
    total += ratriUtaAmount;
    total += additionalGuestsCharge;

    if (extraPurohitaruEnabled) {
      total += extraPurohitaruAmount;
    }

    if (drinkTotalAmount > 0) {
      total += drinkTotalAmount;
    }
    
    return total;
  }
}
