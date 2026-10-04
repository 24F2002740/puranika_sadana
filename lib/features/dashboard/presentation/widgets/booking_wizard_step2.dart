import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puranika_sadana/core/constants/app_colors.dart';

import 'package:puranika_sadana/features/dashboard/data/repositories/hall_repository_provider.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/hall.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/booking_wizard_provider.dart';
import 'package:puranika_sadana/features/dashboard/presentation/widgets/booking_wizard_step3.dart';
import 'package:puranika_sadana/features/dashboard/presentation/widgets/wizard_step_indicator.dart';
import 'package:puranika_sadana/core/services/pricing_service.dart';

class BookingWizardStep2 extends ConsumerStatefulWidget {
  const BookingWizardStep2({super.key});

  @override
  ConsumerState<BookingWizardStep2> createState() => _BookingWizardStep2State();
}

class _BookingWizardStep2State extends ConsumerState<BookingWizardStep2> {

  final Set<String> _expandedHalls = {};

  void _showPriceOverrideDialog(Hall hall) {
    final state = ref.read(bookingWizardProvider);
    final controller = TextEditingController(
      text: (state.hallPriceOverride ?? hall.packageRate).toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Hall Price',
            style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set custom price for this booking only:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
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
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  ref.read(bookingWizardProvider.notifier).updateHallPriceOverride(null);
                  Navigator.pop(context);
                },
                child: const Text('Reset to default',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                ref.read(bookingWizardProvider.notifier).updateHallPriceOverride(newPrice);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    final state = ref.read(bookingWizardProvider);
    final controller = TextEditingController(
      text: state.hallDiscount > 0 ? state.hallDiscount.toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apply Hall Discount',
            style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter discount amount for the hall:', style: TextStyle(fontSize: 14)),
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
              ref.read(bookingWizardProvider.notifier).updateHallDiscount(discount);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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
    if (state.selectedHall != null) {
      ref.read(bookingWizardProvider.notifier).updateMaxStep(3);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BookingWizardStep3()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(bookingWizardProvider);
    final hallsAsync = ref.watch(watchHallsProvider);
    final isEditMode = wizardState.isEditMode;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isEditMode ? Icons.close : Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Edit booking' : 'New booking',
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const WizardStepIndicator(totalSteps: 6, currentStep: 2),
          Expanded(
            child: hallsAsync.when(
              data: (halls) {
                final activeHalls = halls.where((h) => h.isActive).toList();
                if (activeHalls.isEmpty) {
                  return const Center(child: Text('No active halls available.'));
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select hall',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Step 2 of 6',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      ...activeHalls.map((hall) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildHallCard(
                          hall: hall,
                          wizardState: wizardState,
                        ),
                      )),
                      
                      const SizedBox(height: 20),
                      
                      // Vadya Toggle
                      _buildVadyaToggle(wizardState),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          
          // Navigation Buttons
          _buildBottomNav(wizardState),
        ],
      ),
    );
  }

  Widget _buildHallCard({
    required Hall hall,
    required BookingWizardState wizardState,
  }) {
    final isSelected = wizardState.selectedHall?.id == hall.id;
    final isExpanded = _expandedHalls.contains(hall.id);
    final currentOverride = isSelected ? wizardState.hallPriceOverride : null;
    final displayedPrice = currentOverride ?? hall.packageRate;
    final discount = isSelected ? wizardState.hallDiscount : 0.0;
    
    return GestureDetector(
      onTap: () {
        final pricing = PricingService();
        ref.read(bookingWizardProvider.notifier).updateHallSelection(hall, wizardState.addVadya, pricing.vadyaCharge);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 2,
          ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hall.name,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${hall.capacity} Seats',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '₹${(displayedPrice - discount).toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showPriceOverrideDialog(hall),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          ],
                        ),
                        if (isSelected && currentOverride != null)
                          const Text(
                            'Custom rate applied',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedHalls.remove(hall.id);
                              } else {
                                _expandedHalls.add(hall.id);
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "What's included",
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppColors.gold,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
            if (isExpanded) _buildIncludedList(hall),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludedList(Hall hall) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hall.facilities.asMap().entries.map((entry) => _IncludedItem(
          index: entry.key,
          text: entry.value,
        )).toList(),
      ),
    );
  }

  Widget _buildVadyaToggle(BookingWizardState wizardState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add vadya (band)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Optional, +₹6,500',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: wizardState.addVadya,
            onChanged: (value) {
               if (wizardState.selectedHall != null) {
                  final pricing = PricingService();
                  ref.read(bookingWizardProvider.notifier).updateHallSelection(
                    wizardState.selectedHall!, 
                    value,
                    pricing.vadyaCharge,
                  );
               }
            },
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BookingWizardState wizardState) {
    final isEditMode = wizardState.isEditMode;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: wizardState.selectedHall == null ? null : _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isEditMode ? 'Save and Continue' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncludedItem extends StatelessWidget {
  final String text;
  final int index;
  const _IncludedItem({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            '${index + 1}. $text', 
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
