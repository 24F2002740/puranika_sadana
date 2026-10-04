import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puranika_sadana/core/constants/app_colors.dart';
import 'package:puranika_sadana/core/constants/app_dimensions.dart';
import 'package:puranika_sadana/core/services/pricing_service.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/booking.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/booking_wizard_provider.dart';
import 'package:puranika_sadana/features/dashboard/presentation/widgets/wizard_step_indicator.dart';
import 'package:puranika_sadana/features/dashboard/presentation/pages/receipt_preview_screen.dart';


class BookingWizardStep5 extends ConsumerStatefulWidget {
  const BookingWizardStep5({super.key});

  @override
  ConsumerState<BookingWizardStep5> createState() => _BookingWizardStep5State();
}

class _BookingWizardStep5State extends ConsumerState<BookingWizardStep5> {
  final PricingService _pricing = PricingService();
  late TextEditingController _advanceController;
  late String _selectedPaymentMethod;
  late String _advanceStatus;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingWizardProvider);
    _advanceController = TextEditingController(
      text: state.advanceAmount > 0 ? state.advanceAmount.toInt().toString() : '',
    );
    _selectedPaymentMethod = (state.paymentMethod == 'Cash') ? 'Cash' : 'UPI';
    _advanceStatus = state.advanceStatus;
  }

  @override
  void dispose() {
    _advanceController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (Match m) => "${m[1]},",
        );
  }

  void _updateState(double totalAmount) {
    final state = ref.read(bookingWizardProvider);
    final advance = double.tryParse(_advanceController.text) ?? 0;
    
    final hallCharge = state.hallPriceOverride ?? state.selectedHall?.packageRate ?? 0;
    final subtotal = totalAmount + state.hallDiscount + state.cateringDiscount;
    
    // Generate savedExtras list for additional items not covered by explicit fields
    final List<BookingSavedExtra> savedExtras = [];
    
    if (state.addPreviousDayHall) {
      savedExtras.add(BookingSavedExtra(name: 'Previous Day Hall', amount: state.previousDayHallAmount));
    }
    if (state.addBeligeTindi) {
      savedExtras.add(BookingSavedExtra(name: 'Belige Tindi', amount: state.beligeTindiAmount));
    }
    if (state.addSanjeTindi) {
      savedExtras.add(BookingSavedExtra(name: 'Sanje Tindi', amount: state.sanjeTindiAmount));
    }
    if (state.addRatriUta) {
      savedExtras.add(BookingSavedExtra(name: 'Ratri Uta', amount: state.ratriUtaAmount));
    }
    if (state.drinkEnabled) {
      savedExtras.add(BookingSavedExtra(name: state.drinkName, amount: state.drinkTotalAmount));
    }

    ref.read(bookingWizardProvider.notifier).updatePaymentDetails(
          advanceAmount: advance,
          paymentMethod: _selectedPaymentMethod,
          advanceStatus: _advanceStatus,
          totalAmount: totalAmount,
          hallCharge: hallCharge,
          subtotal: subtotal,
          savedExtras: savedExtras,
        );
  }

  void _showDiscountDialog(bool isHall) {
    final state = ref.read(bookingWizardProvider);
    final controller = TextEditingController(
      text: (isHall ? state.hallDiscount : state.cateringDiscount).toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit ${isHall ? 'Hall' : 'Catering'} Discount',
            style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '₹ ',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(controller.text) ?? 0;
              if (isHall) {
                ref.read(bookingWizardProvider.notifier).updateHallDiscount(discount);
              } else {
                ref.read(bookingWizardProvider.notifier).updateCateringDiscount(discount);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingWizardProvider);
    final isEditMode = state.isEditMode;

    final totalAmount = _pricing.calculateTotal(
      hall: state.selectedHall,
      hallOverride: state.hallPriceOverride,
      hallDiscount: state.hallDiscount,
      addVadya: state.addVadya,
      vadyaChargeOverride: state.vadyaCharge,
      cateringManualTotal: state.utaRequired ? state.cateringTotal : 0,
      utaAmount: 0,
      cateringDiscount: state.cateringDiscount,
      addCleaning: state.utaRequired && state.addCleaning,
      cleaningCharge: state.cleaningCharge,
      previousDayHallAmount: state.addPreviousDayHall ? state.previousDayHallAmount : 0,
      beligeTindiAmount: state.addBeligeTindi ? state.beligeTindiAmount : 0,
      sanjeTindiAmount: state.addSanjeTindi ? state.sanjeTindiAmount : 0,
      ratriUtaAmount: state.addRatriUta ? state.ratriUtaAmount : 0,
      extraPurohitaruEnabled: state.extraPurohitaruEnabled,
      extraPurohitaruAmount: state.extraPurohitaruAmount,
      drinkTotalAmount: state.drinkTotalAmount,
      additionalGuestsCharge: state.additionalGuestsCharge,
    );

    final subtotal = totalAmount + state.hallDiscount + state.cateringDiscount;

    final advanceAmount = double.tryParse(_advanceController.text) ?? 0;
    final balanceRemaining = totalAmount - advanceAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isEditMode ? Icons.close : Icons.arrow_back, color: AppColors.gold),
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
          const WizardStepIndicator(totalSteps: 6, currentStep: 5),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  _buildSummaryCard(state, subtotal, totalAmount),
                  const SizedBox(height: AppSpacing.m),
                  _buildPaymentDetailsCard(state, balanceRemaining, totalAmount),
                  if (_selectedPaymentMethod == 'UPI') ...[
                    const SizedBox(height: AppSpacing.m),
                    _buildQRCodeSection(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          _buildBottomButtons(totalAmount, isEditMode),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BookingWizardState state, double subtotal, double totalAmount) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.summarize_rounded, color: AppColors.gold, size: 24),
                SizedBox(width: AppSpacing.s),
                Text('Booking summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            _buildChargeRow(
              'Hall Charge',
              state.hallPriceOverride ?? state.selectedHall?.packageRate ?? 0,
            ),
            if (state.addVadya) _buildChargeRow('Vadya Charge', state.vadyaCharge),
            if (state.extraPurohitaruEnabled) _buildChargeRow('Extra Purohitaru', state.extraPurohitaruAmount),
            if (state.addPreviousDayHall) _buildChargeRow('Previous Day Hall', state.previousDayHallAmount),
            
            if (state.utaRequired) 
              _buildChargeRow(
                state.selectedMenuTier != null ? 'Catering (Tier ${state.selectedMenuTier})' : 'Catering Total', 
                state.cateringTotal
              ),
              
            if (state.addBeligeTindi) _buildChargeRow('Belige Tindi', state.beligeTindiAmount),
            if (state.addSanjeTindi) _buildChargeRow('Sanje Tindi', state.sanjeTindiAmount),
            if (state.addRatriUta) _buildChargeRow('Ratri Uta', state.ratriUtaAmount),
            if (state.drinkEnabled) _buildChargeRow(state.drinkName, state.drinkTotalAmount),
            
            if (state.addCleaning) _buildChargeRow('Cleaning Charge', state.cleaningCharge),
            if (state.additionalGuestsCharge > 0) _buildChargeRow('Additional Guests Charge', state.additionalGuestsCharge),
            
            const Divider(height: 32),
            _buildChargeRow('Subtotal', subtotal, isBold: true),
            
            if (state.hallDiscount > 0)
              _buildDiscountRow('Hall Discount', state.hallDiscount, () => _showDiscountDialog(true))
            else
              _buildAddDiscountButton('Add Hall Discount', () => _showDiscountDialog(true)),

            if (state.cateringDiscount > 0)
              _buildDiscountRow('Catering Discount', state.cateringDiscount, () => _showDiscountDialog(false))
            else if (state.utaRequired)
              _buildAddDiscountButton('Add Catering Discount', () => _showDiscountDialog(false)),

            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('₹${_formatCurrency(totalAmount)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: isBold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          Text('₹${_formatCurrency(amount)}', style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(String label, double amount, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 14, color: Colors.grey),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          Text('- ₹${_formatCurrency(amount)}', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddDiscountButton(String label, VoidCallback onPressed) {
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 14, color: Colors.grey),
        label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(BookingWizardState state, double balanceRemaining, double totalAmount) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.gold, size: 24),
                SizedBox(width: AppSpacing.s),
                Text('Payment details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                const Expanded(
                  child: Text('Advance amount', style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                ),
                SizedBox(
                  width: 150,
                  height: 48,
                  child: TextField(
                    controller: _advanceController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {});
                      _updateState(totalAmount);
                    },
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.m), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.m), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.m), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EF),
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppColors.gold.withAlpha(25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Balance remaining', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  Text('₹${_formatCurrency(balanceRemaining)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text('Payment method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(child: _buildSegmentedButton('UPI', Icons.qr_code_scanner_rounded, 'UPI / QR', totalAmount)),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: _buildSegmentedButton('Cash', Icons.payments_rounded, 'Cash', totalAmount)),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            const Text('Advance status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                _buildRadioOption('Paid', 'Paid', totalAmount),
                const SizedBox(width: AppSpacing.l),
                _buildRadioOption('Pending', 'Pending', totalAmount),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9E7),
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppColors.gold.withAlpha(51)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: AppColors.gold, size: 22),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Balance amount will be collected after the event.',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton(String value, IconData icon, String label, double totalAmount) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
        _updateState(totalAmount);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: isSelected ? AppColors.gold : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.gold : AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value, String label, double totalAmount) {
    final isSelected = _advanceStatus == value;

    return InkWell(
      onTap: () {
        setState(() => _advanceStatus = value);
        _updateState(totalAmount);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _advanceStatus,
            onChanged: (val) {
              if (val != null) {
                setState(() => _advanceStatus = val);
                _updateState(totalAmount);
              }
            },
            activeColor: AppColors.primary,
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const Text('UPI ID: puranikasadana@oksbi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, width: 2), borderRadius: BorderRadius.circular(AppRadius.m)),
                  child: Image.network(
                    'https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=upi://pay?pa=puranikasadana@oksbi&pn=Puranika%20Sadana',
                    height: 110,
                    width: 110,
                    errorBuilder: (c, e, s) => const Icon(Icons.qr_code_2, size: 110),
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan & pay using any UPI app', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: AppSpacing.s),
                      Text('After payment, confirm to complete booking.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(double totalAmount, bool isEditMode) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              ),
              child: const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateState(totalAmount);
                ref.read(bookingWizardProvider.notifier).updateMaxStep(6);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptPreviewScreen()));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                elevation: 2,
              ),
              child: Text(isEditMode ? 'Save and Continue' : 'Confirm Booking', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
