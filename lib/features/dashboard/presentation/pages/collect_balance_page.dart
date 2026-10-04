import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/booking_status.dart';
import '../../data/repositories/booking_repository_provider.dart';

class CollectBalancePage extends ConsumerStatefulWidget {
  final Booking booking;

  const CollectBalancePage({super.key, required this.booking});

  @override
  ConsumerState<CollectBalancePage> createState() => _CollectBalancePageState();
}

class _CollectBalancePageState extends ConsumerState<CollectBalancePage> {
  final _pricing = PricingService();
  late double _amountToCollect;
  String _paymentMethod = 'Cash';
  late TextEditingController _amountController;
  late TextEditingController _newGuestCountController;
  late TextEditingController _additionalChargeController;
  late TextEditingController _hallDiscountController;
  late TextEditingController _cateringDiscountController;
  
  String _activeOption = 'Full'; // 'Full', 'Half', 'Custom'
  bool _isSaving = false;
  bool _guestCountIncreased = false;

  @override
  void initState() {
    super.initState();
    _hallDiscountController = TextEditingController(text: widget.booking.hallDiscount.toInt().toString());
    _cateringDiscountController = TextEditingController(text: widget.booking.cateringDiscount.toInt().toString());
    
    _guestCountIncreased = (widget.booking.finalGuestCount ?? widget.booking.guestCount) > widget.booking.guestCount;
    
    _newGuestCountController = TextEditingController(
      text: _guestCountIncreased 
          ? widget.booking.finalGuestCount.toString() 
          : (widget.booking.guestCount + 1).toString()
    );
    
    _additionalChargeController = TextEditingController(
      text: _guestCountIncreased 
          ? widget.booking.additionalGuestsCharge.toInt().toString() 
          : '0'
    );

    // Initial calculation
    final remaining = _currentRemaining;
    _amountToCollect = remaining;
    _amountController = TextEditingController(text: remaining.toInt().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _newGuestCountController.dispose();
    _additionalChargeController.dispose();
    _hallDiscountController.dispose();
    _cateringDiscountController.dispose();
    super.dispose();
  }

  double get _additionalCharge {
    if (!_guestCountIncreased) return 0;
    
    final oldCount = widget.booking.guestCount;
    final isManual = oldCount <= _pricing.manualEntryThreshold;
    
    if (isManual) {
      return double.tryParse(_additionalChargeController.text) ?? 0;
    } else {
      final newCount = int.tryParse(_newGuestCountController.text) ?? oldCount;
      final extra = (newCount - oldCount).clamp(0, 9999);
      
      double rate = widget.booking.menuRateOverride ?? 0;
      if (rate <= 0) {
        if (widget.booking.cateringTier == 1) rate = _pricing.menu1Price;
        if (widget.booking.cateringTier == 2) rate = _pricing.menu2Price;
        if (widget.booking.cateringTier == 3) rate = _pricing.menu3Price;
      }
      return extra * rate;
    }
  }

  double get _currentHallDiscount => double.tryParse(_hallDiscountController.text) ?? 0;
  double get _currentCateringDiscount => double.tryParse(_cateringDiscountController.text) ?? 0;

  double get _subtotalWithoutDiscounts {
    // We calculate subtotal = (saved total - additionalGuestsCharge) + saved discounts.
    // If booking.subtotal is already set and > 0, we use it as the base.
    if (widget.booking.subtotal > 0) {
      return widget.booking.subtotal;
    }
    return (widget.booking.totalAmount - widget.booking.additionalGuestsCharge) 
           + widget.booking.hallDiscount + widget.booking.cateringDiscount;
  }

  double get _currentTotal => _subtotalWithoutDiscounts + _additionalCharge - _currentHallDiscount - _currentCateringDiscount;
  double get _currentRemaining => _currentTotal - widget.booking.advancePaid;

  void _updateAmount(double amount, String option) {
    setState(() {
      _amountToCollect = amount;
      _activeOption = option;
      _amountController.text = amount.toInt().toString();
    });
  }

  void _onCollect() async {
    if (_amountToCollect <= 0 || _isSaving) return;

    int? finalGuestCount;
    if (_guestCountIncreased) {
      finalGuestCount = int.tryParse(_newGuestCountController.text);
      if (finalGuestCount == null || finalGuestCount <= widget.booking.guestCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New guest count must be greater than original count')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final additionalCharge = _additionalCharge;
    final updatedTotal = _currentTotal;
    final updatedPaid = widget.booking.advancePaid + _amountToCollect;
    final remaining = updatedTotal - updatedPaid;
    
    final newPayment = PaymentEntry(
      date: DateTime.now(),
      method: _paymentMethod,
      amount: _amountToCollect,
    );

    final updatedBooking = widget.booking.copyWith(
      totalAmount: updatedTotal,
      subtotal: _subtotalWithoutDiscounts, // Keep original subtotal or update if needed
      advancePaid: updatedPaid,
      hallDiscount: _currentHallDiscount,
      cateringDiscount: _currentCateringDiscount,
      paymentHistory: [...widget.booking.paymentHistory, newPayment],
      status: remaining <= 0 ? BookingStatus.completed : widget.booking.status,
      finalGuestCount: _guestCountIncreased ? finalGuestCount : widget.booking.guestCount,
      additionalGuestsCharge: additionalCharge,
    );

    try {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBooking(updatedBooking);
      
      await NotificationService().scheduleBookingReminders(updatedBooking);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₹${NumberFormat('#,##,###').format(_amountToCollect)} collected successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##,###');
    final isManual = widget.booking.guestCount <= _pricing.manualEntryThreshold;
    final resultingBalance = _currentRemaining - _amountToCollect;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collect Balance Payment',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '#${widget.booking.id} · ${widget.booking.brideName} & ${widget.booking.groomName}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal (before discounts)', '₹${currencyFormat.format(_subtotalWithoutDiscounts)}', isBold: true),
                  if (_currentHallDiscount > 0)
                    _buildSummaryRow('Hall Discount', '-₹${currencyFormat.format(_currentHallDiscount)}', valueColor: Colors.green),
                  if (_currentCateringDiscount > 0)
                    _buildSummaryRow('Catering Discount', '-₹${currencyFormat.format(_currentCateringDiscount)}', valueColor: Colors.green),
                  if (_guestCountIncreased) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow('Additional guests charge', '₹${currencyFormat.format(_additionalCharge)}', valueColor: AppColors.gold),
                  ],
                  const Divider(height: 24, color: Color(0xFFF1E9D9)),
                  _buildSummaryRow('Final Total', '₹${currencyFormat.format(_currentTotal)}', isBold: true),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Total paid so far', '₹${currencyFormat.format(widget.booking.advancePaid)}', valueColor: AppColors.success),
                  const Divider(height: 24, color: Color(0xFFF1E9D9)),
                  _buildSummaryRow(
                    'Remaining balance', 
                    '₹${currencyFormat.format(_currentRemaining)}', 
                    valueColor: AppColors.primary,
                    isBold: true,
                    fontSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Discounts Section
            const Text(
              'EDIT DISCOUNTS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(flex: 3, child: Text('Hall Discount', style: TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _hallDiscountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (val) {
                            setState(() {});
                            if (_activeOption == 'Full') {
                              _amountController.text = _currentRemaining.toInt().toString();
                              _amountToCollect = _currentRemaining;
                            }
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(flex: 3, child: Text('Catering Discount', style: TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _cateringDiscountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (val) {
                            setState(() {});
                            if (_activeOption == 'Full') {
                              _amountController.text = _currentRemaining.toInt().toString();
                              _amountToCollect = _currentRemaining;
                            }
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Guest Count Increase Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Did guest count increase on the day?',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  Switch(
                    value: _guestCountIncreased,
                    onChanged: _isSaving ? null : (val) {
                      setState(() {
                        _guestCountIncreased = val;
                        // Reset to full remaining balance when toggle changes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                           _updateAmount(_currentRemaining, 'Full');
                        });
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            if (_guestCountIncreased) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORIGINAL GUESTS: ${widget.booking.guestCount}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('New Guest Count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _newGuestCountController,
                                enabled: !_isSaving,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (val) {
                                  setState(() {});
                                  if (_activeOption == 'Full') {
                                    _amountController.text = _currentRemaining.toInt().toString();
                                    _amountToCollect = _currentRemaining;
                                  }
                                },
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isManual ? 'Additional Amount' : 'Additional Charge', 
                                   style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              if (isManual)
                                TextField(
                                  controller: _additionalChargeController,
                                  enabled: !_isSaving,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (val) {
                                    setState(() {});
                                    if (_activeOption == 'Full') {
                                      _amountController.text = _currentRemaining.toInt().toString();
                                      _amountToCollect = _currentRemaining;
                                    }
                                  },
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    '₹ ${currencyFormat.format(_additionalCharge)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            const Text(
              'AMOUNT TO COLLECT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            
            // Amount Input
            TextField(
              controller: _amountController,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                setState(() {
                  _amountToCollect = double.tryParse(val) ?? 0;
                  _activeOption = 'Custom';
                });
              },
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: _isSaving ? Colors.grey.shade100 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Options
            Row(
              children: [
                _buildQuickOption('Full Balance', _currentRemaining, 'Full'),
                const SizedBox(width: 8),
                _buildQuickOption('Half (₹${currencyFormat.format(_currentRemaining / 2)})', _currentRemaining / 2, 'Half'),
                const SizedBox(width: 8),
                _buildQuickOption('Custom', _amountToCollect, 'Custom'),
              ],
            ),
            const SizedBox(height: 30),

            const Text(
              'PAYMENT METHOD',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildMethodCard('Cash', Icons.payments_outlined, AppColors.success)),
                const SizedBox(width: 16),
                Expanded(child: _buildMethodCard('UPI', Icons.qr_code_2_outlined, Colors.indigo)),
              ],
            ),
            const SizedBox(height: 30),

            // Preview Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'After this payment',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance will be ₹${currencyFormat.format(resultingBalance.clamp(0, double.infinity))} — booking will be marked ${resultingBalance <= 0 ? 'Fully Paid' : 'Partially Paid'}.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : (_amountToCollect > 0 && _amountToCollect <= _currentRemaining + 0.1 ? _onCollect : null),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: _isSaving 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                'Collect ₹${currencyFormat.format(_amountToCollect)} ($_paymentMethod)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool isBold = false, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOption(String label, double amount, String option) {
    final isActive = _activeOption == option;
    return Expanded(
      child: InkWell(
        onTap: _isSaving ? null : () => _updateAmount(amount, option),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? AppColors.primary : AppColors.gold.withOpacity(0.2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(String method, IconData icon, Color iconColor) {
    final isActive = _paymentMethod == method;
    return InkWell(
      onTap: _isSaving ? null : () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.gold.withOpacity(0.2), 
            width: isActive ? 1.5 : 1
          ),
          boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 8)] : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.05) : Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              method,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
