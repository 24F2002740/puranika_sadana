import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puranika_sadana/core/constants/app_colors.dart';
import 'package:puranika_sadana/core/constants/app_constants.dart';
import 'package:puranika_sadana/core/services/pricing_service.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/booking_wizard_provider.dart';
import 'package:puranika_sadana/features/dashboard/presentation/widgets/wizard_step_indicator.dart';
import 'booking_wizard_step5.dart';

class BookingWizardStep4 extends ConsumerStatefulWidget {
  const BookingWizardStep4({super.key});

  @override
  ConsumerState<BookingWizardStep4> createState() => _BookingWizardStep4State();
}

class _BookingWizardStep4State extends ConsumerState<BookingWizardStep4> {
  final PricingService _pricing = PricingService();
  final _cleaningController = TextEditingController();
  final _cateringTotalController = TextEditingController();
  final _customNameController = TextEditingController();
  final _customRateController = TextEditingController();

  // Additional Services Controllers
  final _prevDayHallAmountController = TextEditingController();
  final _beligeGuestController = TextEditingController();
  final _beligeItemsController = TextEditingController();
  final _beligeAmountController = TextEditingController();
  final _sanjeGuestController = TextEditingController();
  final _sanjeItemsController = TextEditingController();
  final _sanjeAmountController = TextEditingController();
  final _ratriGuestController = TextEditingController();
  final _ratriItemsController = TextEditingController();
  final _ratriAmountController = TextEditingController();

  // Drink Controllers
  final _drinkNameController = TextEditingController(text: 'ಶರಬತ್');
  final _drinkMemberController = TextEditingController();
  final _drinkAmountController = TextEditingController();

  bool _utaRequired = false;
  int? _selectedTier;
  bool _addPalav = false;
  bool _addPoori = false;
  bool _addIceCream = false;
  bool _addWater = false;
  bool _addCleaning = false;
  List<CustomExtra> _customExtras = [];
  List<String> _cateringItems = [];
  int? _openTierIndex;

  // Additional Services Toggles
  bool _addPreviousDayHall = false;
  bool _addBeligeTindi = false;
  bool _addSanjeTindi = false;
  bool _addRatriUta = false;

  // Drink Toggle
  bool _drinkEnabled = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingWizardProvider);
    _utaRequired = state.utaRequired;
    _selectedTier = state.selectedMenuTier;
    _addPalav = state.addPalav;
    _addPoori = state.addPoori;
    _addIceCream = state.addIceCream;
    _addWater = state.addWater;
    _addCleaning = state.addCleaning;
    _cleaningController.text = state.cleaningCharge > 0
        ? state.cleaningCharge.toInt().toString()
        : _pricing.defaultCleaningCharge.toInt().toString();
    _customExtras = List.from(state.customExtras);
    _cateringItems = List.from(state.cateringItems);
    
    _cateringTotalController.text = state.cateringTotal > 0 ? state.cateringTotal.toInt().toString() : '';

    // Initialize Additional Services
    _addPreviousDayHall = state.addPreviousDayHall;
    _prevDayHallAmountController.text = state.previousDayHallAmount > 0 ? state.previousDayHallAmount.toInt().toString() : '';

    _addBeligeTindi = state.addBeligeTindi;
    _beligeGuestController.text = state.beligeTindiGuestCount > 0 ? state.beligeTindiGuestCount.toString() : '';
    _beligeItemsController.text = state.beligeTindiItems;
    _beligeAmountController.text = state.beligeTindiAmount > 0 ? state.beligeTindiAmount.toInt().toString() : '';

    _addSanjeTindi = state.addSanjeTindi;
    _sanjeGuestController.text = state.sanjeTindiGuestCount > 0 ? state.sanjeTindiGuestCount.toString() : '';
    _sanjeItemsController.text = state.sanjeTindiItems;
    _sanjeAmountController.text = state.sanjeTindiAmount > 0 ? state.sanjeTindiAmount.toInt().toString() : '';

    _addRatriUta = state.addRatriUta;
    _ratriGuestController.text = state.ratriUtaGuestCount > 0 ? state.ratriUtaGuestCount.toString() : '';
    _ratriItemsController.text = state.ratriUtaItems;
    _ratriAmountController.text = state.ratriUtaAmount > 0 ? state.ratriUtaAmount.toInt().toString() : '';

    // Initialize Drink
    _drinkEnabled = state.drinkEnabled;
    _drinkNameController.text = state.drinkName;
    _drinkMemberController.text = state.drinkMemberCount > 0 ? state.drinkMemberCount.toString() : '0';
    _drinkAmountController.text = state.drinkTotalAmount > 0 ? state.drinkTotalAmount.toInt().toString() : '0';
  }

  @override
  void dispose() {
    _cleaningController.dispose();
    _cateringTotalController.dispose();
    _customNameController.dispose();
    _customRateController.dispose();
    _prevDayHallAmountController.dispose();
    _beligeGuestController.dispose();
    _beligeItemsController.dispose();
    _beligeAmountController.dispose();
    _sanjeGuestController.dispose();
    _sanjeItemsController.dispose();
    _sanjeAmountController.dispose();
    _ratriGuestController.dispose();
    _ratriItemsController.dispose();
    _ratriAmountController.dispose();
    _drinkNameController.dispose();
    _drinkMemberController.dispose();
    _drinkAmountController.dispose();
    super.dispose();
  }

  void _addCustomItem() {
    final name = _customNameController.text;
    final rate = double.tryParse(_customRateController.text) ?? 0;
    if (name.isNotEmpty && rate > 0) {
      setState(() {
        _customExtras.add(CustomExtra(name: name, rate: rate));
        _customNameController.clear();
        _customRateController.clear();
      });
    }
  }

  double _calculateBaseUtaAmount(int guestCount) {
    if (!_utaRequired || _selectedTier == null) return 0;
    double rate = 0;
    if (_selectedTier == 1) rate = _pricing.menu1Price;
    else if (_selectedTier == 2) rate = _pricing.menu2Price;
    else if (_selectedTier == 3) rate = _pricing.menu3Price;
    return rate * guestCount;
  }

  double _calculateUtaTotal(int guestCount) {
    if (!_utaRequired) return 0;
    
    double rate = 0;
    if (_selectedTier == 1) {
      rate = _pricing.menu1Price;
    } else if (_selectedTier == 2) {
      rate = _pricing.menu2Price;
    } else if (_selectedTier == 3) {
      rate = _pricing.menu3Price;
    }

    double total = rate * guestCount;

    if (_addPalav) total += _pricing.palavSaladPrice * guestCount;
    if (_addPoori) total += _pricing.pooriSaguPrice * guestCount;
    if (_addIceCream) total += _pricing.iceCreamPrice * guestCount;
    if (_addWater) total += _pricing.waterBottlePrice * guestCount;

    return total;
  }

  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
      (Match m) => "${m[1]},",
    );
  }

  void _showDiscountDialog() {
    final state = ref.read(bookingWizardProvider);
    final controller = TextEditingController(
      text: state.cateringDiscount > 0 ? state.cateringDiscount.toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apply Catering Discount',
            style: TextStyle(color: Color(0xFF3D1608), fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter discount amount for catering:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(controller.text) ?? 0;
              ref.read(bookingWizardProvider.notifier).updateCateringDiscount(discount);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D1608),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    final state = ref.read(bookingWizardProvider);
    final isManualMode = state.guestCount <= _pricing.manualEntryThreshold;

    double cateringTotalResult = 0;
    double utaAmountBase = 0;
    List<String> itemsToSave = [];

    if (_utaRequired) {
      if (isManualMode) {
        cateringTotalResult = double.tryParse(_cateringTotalController.text) ?? 0;
        utaAmountBase = cateringTotalResult;
        itemsToSave = List.from(_cateringItems);
      } else {
        utaAmountBase = _calculateBaseUtaAmount(state.guestCount);
        cateringTotalResult = _calculateUtaTotal(state.guestCount);

        // Fold custom extras into catering total
        for (var extra in _customExtras) {
          cateringTotalResult += extra.isFlat ? extra.rate : (extra.rate * state.guestCount);
        }

        // Tier base items
        if (_selectedTier == 1) {
          itemsToSave = List.from(_pricing.menu1Dishes);
        } else if (_selectedTier == 2) {
          itemsToSave = List.from(_pricing.menu2Dishes);
        } else if (_selectedTier == 3) {
          itemsToSave = List.from(_pricing.menu3Dishes);
        }

        // Append extra names to itemsToSave for display in chip lists (ensuring uniqueness)
        void addItemIfMissing(String name) {
          if (!itemsToSave.contains(name)) itemsToSave.add(name);
        }

        if (_addPalav) addItemIfMissing('Palav + Salad');
        if (_addPoori) addItemIfMissing('2 Poori + Sagu');
        if (_addIceCream) addItemIfMissing('Ice Cream');
        if (_addWater) addItemIfMissing('Water Bottle');
        for (var extra in _customExtras) {
          addItemIfMissing(extra.name);
        }
      }
    }

    final drinkAmt = double.tryParse(_drinkAmountController.text) ?? 0;

    ref.read(bookingWizardProvider.notifier).updateMenuSelection(
          utaRequired: _utaRequired,
          tier: _selectedTier,
          palav: _addPalav,
          poori: _addPoori,
          iceCream: _addIceCream,
          water: _addWater,
          cleaning: _addCleaning,
          cleaningAmt: double.tryParse(_cleaningController.text) ?? 0,
          custom: _customExtras,
          cateringTotal: cateringTotalResult,

          utaAmount: utaAmountBase,
          cateringItems: _utaRequired ? itemsToSave : [],
          addPreviousDayHall: _addPreviousDayHall,
          previousDayHallAmount: double.tryParse(_prevDayHallAmountController.text) ?? 0,
          addBeligeTindi: _addBeligeTindi,
          beligeTindiGuestCount: int.tryParse(_beligeGuestController.text) ?? 0,
          beligeTindiItems: _beligeItemsController.text,
          beligeTindiAmount: double.tryParse(_beligeAmountController.text) ?? 0,
          addSanjeTindi: _addSanjeTindi,
          sanjeTindiGuestCount: int.tryParse(_sanjeGuestController.text) ?? 0,
          sanjeTindiItems: _sanjeItemsController.text,
          sanjeTindiAmount: double.tryParse(_sanjeAmountController.text) ?? 0,
          addRatriUta: _addRatriUta,
          ratriUtaGuestCount: int.tryParse(_ratriGuestController.text) ?? 0,
          ratriUtaItems: _ratriItemsController.text,
          ratriUtaAmount: double.tryParse(_ratriAmountController.text) ?? 0,
          drinkEnabled: _drinkEnabled && drinkAmt > 0,
          drinkName: _drinkNameController.text,
          drinkMemberCount: int.tryParse(_drinkMemberController.text) ?? 0,
          drinkTotalAmount: drinkAmt,
        );
    ref.read(bookingWizardProvider.notifier).updateMaxStep(5);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookingWizardStep5()),
    );
  }

  void _showEditItemsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditItemsBottomSheet(
        initialItems: _cateringItems,
        onSave: (newItems) {
          setState(() {
            _cateringItems = newItems;
          });
        },
      ),
    );
  }

  void _showEditDrinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Drink Details', style: TextStyle(color: Color(0xFF3D1608), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _drinkNameController,
                decoration: const InputDecoration(labelText: 'Drink Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _drinkMemberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of Members'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _drinkAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount', prefixText: '₹ '),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D1608), foregroundColor: Colors.white),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingWizardProvider);
    final isManualRequired = state.guestCount <= _pricing.manualEntryThreshold;
    final isEditMode = state.isEditMode;

    // Inclusive total for display (base uta + addons + custom extras)
    double cateringDisplayTotal = 0.0;
    if (_utaRequired) {
       if (isManualRequired) {
          cateringDisplayTotal = double.tryParse(_cateringTotalController.text) ?? 0.0;
       } else {
          cateringDisplayTotal = _calculateUtaTotal(state.guestCount);
          for (var extra in _customExtras) {
            cateringDisplayTotal += extra.isFlat ? extra.rate : (extra.rate * state.guestCount);
          }
       }
    }

    final discount = state.cateringDiscount;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1608),
        elevation: 0,
        leading: IconButton(
          icon: Icon(isEditMode ? Icons.close : Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Edit booking' : 'New booking',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const WizardStepIndicator(totalSteps: 6, currentStep: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Catering Selection',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3D1608)),
                  ),
                  const Text(
                    'Step 4 of 6',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Uta Required Toggle
                  SwitchListTile(
                    title: const Text(
                      'Uta Required',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(_utaRequired ? 'Catering pricing logic active' : 'Uta amount will be ₹0'),
                    contentPadding: EdgeInsets.zero,
                    value: _utaRequired,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.green,
                    onChanged: (val) => setState(() => _utaRequired = val),
                  ),
                  const Divider(),

                  if (_utaRequired) ...[
                    if (!isManualRequired) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'CHOOSE A CATERING TIER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      RadioGroup<int>(
                        value: _selectedTier,
                        onChanged: (val) => setState(() => _selectedTier = val),
                        child: Column(
                          children: [
                            _buildTierCard(1, 'Tier 1', _pricing.menu1Price, _pricing.menu1Dishes),
                            const SizedBox(height: 12),
                            _buildTierCard(2, 'Tier 2', _pricing.menu2Price, _pricing.menu2Dishes),
                            const SizedBox(height: 12),
                            _buildTierCard(3, 'Tier 3', _pricing.menu3Price, _pricing.menu3Dishes),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Optional extras',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      _buildExtrasCard(),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'MANUAL CATERING AMOUNT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1F4A0E14), blurRadius: 14, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Manual Catering Amount',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                TextButton.icon(
                                  onPressed: _showDiscountDialog,
                                  icon: const Icon(Icons.sell_outlined, size: 14, color: AppColors.gold),
                                  label: Text(
                                    discount > 0 ? '-₹${discount.toInt()}' : 'Apply Discount',
                                    style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _cateringTotalController,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Enter total catering charge',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: const Color(0xFFFBF7EE),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manual entry enabled because guest count (${state.guestCount}) is ≤ ${_pricing.manualEntryThreshold}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                            const Divider(height: 32),
                            const Text(
                              'Menu Items',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3D1608)),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _cateringItems.map((item) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF7EE),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                              )).toList(),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _showEditItemsDialog,
                              icon: const Icon(Icons.edit, size: 16, color: Colors.amber),
                              label: const Text('Edit Menu Items', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),
                  _buildAdditionalServicesCard(),

                  const SizedBox(height: 24),
                  _buildDrinkSection(),

                  const SizedBox(height: 24),
                  _buildChecklistCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Summary Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7EE),
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Guests', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${state.guestCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_utaRequired)
                      TextButton.icon(
                        onPressed: _showDiscountDialog,
                        icon: const Icon(Icons.sell_outlined, size: 14, color: AppColors.gold),
                        label: Text(
                          discount > 0 ? '-₹${discount.toInt()}' : 'Apply Discount',
                          style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
                if (_utaRequired) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Catering total',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_formatCurrency(cateringDisplayTotal - discount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D1608),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3D1608),
                          side: const BorderSide(color: Color(0xFF3D1608)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_utaRequired && isManualRequired && (double.tryParse(_cateringTotalController.text) ?? 0) <= 0) ? null : _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D1608),
                          foregroundColor: const Color(0xFFFBF7EE),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isEditMode ? 'Save and Continue' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1F4A0E14), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ತರಬೇಕಾದ ವಸ್ತುಗಳು', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...AppConstants.bookingChecklist.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('${item['kan']} (${item['eng']})', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdditionalServicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1F4A0E14), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ADDITIONAL SERVICES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 16),

          // Previous Day Hall
          _buildServiceToggle(
            title: 'Previous Day Hall Booking',
            value: _addPreviousDayHall,
            onChanged: (v) => setState(() => _addPreviousDayHall = v),
          ),
          if (_addPreviousDayHall) ...[
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('Hall used one day before the wedding', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
            _buildManualAmountField('Amount', _prevDayHallAmountController),
            const SizedBox(height: 16),
          ],

          const Divider(),

          // Belige Tindi
          _buildServiceToggle(
            title: 'Belige Tindi (Morning Breakfast)',
            value: _addBeligeTindi,
            onChanged: (v) => setState(() => _addBeligeTindi = v),
          ),
          if (_addBeligeTindi) ...[
            _buildServiceFields(_beligeGuestController, _beligeItemsController, _beligeAmountController),
            const SizedBox(height: 16),
          ],

          const Divider(),

          // Sanje Tindi
          _buildServiceToggle(
            title: 'Sanje Tindi (Evening Snacks)',
            value: _addSanjeTindi,
            onChanged: (v) => setState(() => _addSanjeTindi = v),
          ),
          if (_addSanjeTindi) ...[
            _buildServiceFields(_sanjeGuestController, _sanjeItemsController, _sanjeAmountController),
            const SizedBox(height: 16),
          ],

          const Divider(),

          // Ratri Uta
          _buildServiceToggle(
            title: 'Ratri Uta (Night Dinner)',
            value: _addRatriUta,
            onChanged: (v) => setState(() => _addRatriUta = v),
          ),
          if (_addRatriUta) ...[
            _buildServiceFields(_ratriGuestController, _ratriItemsController, _ratriAmountController),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildDrinkSection() {
    final drinkAmt = double.tryParse(_drinkAmountController.text) ?? 0;
    final hasCharge = drinkAmt > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1F4A0E14), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ಶರಬತ್', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3D1608))),
              Row(
                children: [
                  TextButton(
                    onPressed: _showEditDrinkDialog,
                    child: const Text('Edit', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                  Switch(
                    value: _drinkEnabled,
                    onChanged: (val) => setState(() => _drinkEnabled = val),
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ],
          ),
          if (_drinkEnabled) ...[
            Row(
              children: [
                Icon(
                  hasCharge ? Icons.check_circle : Icons.info_outline,
                  color: hasCharge ? Colors.green : Colors.grey,
                  size: 16
                ),
                const SizedBox(width: 4),
                Text(
                  hasCharge ? 'Included' : 'Charge not entered (₹0)',
                  style: TextStyle(fontSize: 12, color: hasCharge ? Colors.green : Colors.grey, fontWeight: FontWeight.w500)
                ),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
              },
              children: [
                const TableRow(
                  children: [
                    Text('Drink', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Members', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_drinkNameController.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_drinkMemberController.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('₹${_drinkAmountController.text}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceToggle({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: Colors.green,
    );
  }

  Widget _buildManualAmountField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '₹ ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildServiceFields(TextEditingController guestCtrl, TextEditingController itemsCtrl, TextEditingController amountCtrl) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: guestCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Guest Count',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: itemsCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Items',
            hintText: 'e.g. Idli, Vada, Chutney',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: const TextStyle(fontFamily: 'NotoSansKannada'),
        ),
      ],
    );
  }

  Widget _buildTierCard(int tier, String name, double price, List<String> dishes) {
    final isSelected = _selectedTier == tier;
    final isExpanded = _openTierIndex == tier;
    final discount = ref.watch(bookingWizardProvider).cateringDiscount;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Radio<int>(
                    value: tier,
                    groupValue: _selectedTier,
                    onChanged: (val) => setState(() => _selectedTier = val),
                    activeColor: Colors.amber,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Color(0xFF3D1608),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isSelected)
                              TextButton.icon(
                                onPressed: _showDiscountDialog,
                                icon: const Icon(Icons.sell_outlined, size: 14, color: AppColors.gold),
                                label: Text(
                                  discount > 0 ? '-₹${discount.toInt()}' : 'Apply Discount',
                                  style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _openTierIndex = isExpanded ? null : tier;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "What's included",
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.amber.shade700,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${price.toInt()}/plate',
                    style: const TextStyle(
                      color: Color(0xFF3D1608),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dishes.map((dish) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      dish,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtrasCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F4A0E14),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildExtraRow('Palav + salad', '+₹${_pricing.palavSaladPrice.toInt()}/plate', _addPalav, (v) => setState(() => _addPalav = v!)),
          _buildExtraRow('2 poori + sagu', '+₹${_pricing.pooriSaguPrice.toInt()}/plate', _addPoori, (v) => setState(() => _addPoori = v!)),
          _buildExtraRow('Icecream', '+₹${_pricing.iceCreamPrice.toInt()}/plate', _addIceCream, (v) => setState(() => _addIceCream = v!)),
          _buildExtraRow('Water bottle (500ml)', '+₹${_pricing.waterBottlePrice.toInt()}/plate', _addWater, (v) => setState(() => _addWater = v!)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: _addCleaning,
                  onChanged: (v) => setState(() => _addCleaning = v!),
                  activeColor: const Color(0xFF3D1608),
                ),
                const Expanded(
                  child: Text(
                    'Cleaning charge',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 36,
                  child: TextFormField(
                    controller: _cleaningController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'amount',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.amber.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),
          ..._customExtras.map((extra) => _buildCustomExtraRow(extra)),

          Row(
            children: [
              const Icon(Icons.add, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 36,
                  child: TextFormField(
                    controller: _customNameController,
                    decoration: const InputDecoration(
                      hintText: 'Add item name',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 36,
                  child: TextFormField(
                    controller: _customRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'rate',
                      prefixText: '₹ ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _addCustomItem,
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraRow(String label, String price, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3D1608),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomExtraRow(CustomExtra extra) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_box, color: Color(0xFF3D1608), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              extra.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            extra.isFlat ? '+₹${extra.rate.toInt()}' : '+₹${extra.rate.toInt()}/plate',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _customExtras.remove(extra);
              });
            },
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EditItemsBottomSheet extends StatefulWidget {
  final List<String> initialItems;
  final Function(List<String>) onSave;

  const _EditItemsBottomSheet({required this.initialItems, required this.onSave});

  @override
  State<_EditItemsBottomSheet> createState() => _EditItemsBottomSheetState();
}

class _EditItemsBottomSheetState extends State<_EditItemsBottomSheet> {
  late List<String> _items;
  final _addItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  void _editItem(int index) {
    final controller = TextEditingController(text: _items[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _items[index] = controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this menu item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _items.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (_addItemController.text.isNotEmpty) {
      setState(() {
        _items.add(_addItemController.text);
        _addItemController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('EDIT MENU ITEMS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D1608))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                title: Text(_items[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editItem(index)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(index)),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addItemController,
                        decoration: const InputDecoration(hintText: 'Item Name', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_items);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D1608), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RadioGroup<T> extends StatelessWidget {
  final T? value;
  final ValueChanged<T?> onChanged;
  final Widget child;

  const RadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _RadioGroupScope<T>(
      groupValue: value,
      onChanged: onChanged,
      child: child,
    );
  }

  static T? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RadioGroupScope<T>>()?.groupValue;
  }

  static ValueChanged<T?>? onChangedOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RadioGroupScope<T>>()?.onChanged;
  }
}

class _RadioGroupScope<T> extends InheritedWidget {
  final T? groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioGroupScope({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  @override
  bool updateShouldNotify(_RadioGroupScope<T> oldWidget) {
    return groupValue != oldWidget.groupValue;
  }
}
