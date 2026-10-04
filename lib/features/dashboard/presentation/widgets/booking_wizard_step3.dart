import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/pricing_service.dart';

import '../providers/booking_wizard_provider.dart';
import 'wizard_step_indicator.dart';
import 'booking_wizard_step4.dart';

class BookingWizardStep3 extends ConsumerStatefulWidget {
  const BookingWizardStep3({super.key});

  @override
  ConsumerState<BookingWizardStep3> createState() => _BookingWizardStep3State();
}

class _BookingWizardStep3State extends ConsumerState<BookingWizardStep3> {
  final _guestCountController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _extraPurohitaruController = TextEditingController(text: '7000');
  final List<String> _lagnas = ["Abhijit lagna", "Kanya lagna", "Meena lagna"];
  String? _selectedLagna;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _extraPurohitaruEnabled = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingWizardProvider);
    _selectedLagna = state.lagna;
    _selectedDate = state.eventDate;
    _selectedTime = state.muhurthamTime;
    _extraPurohitaruEnabled = state.extraPurohitaruEnabled;
    _extraPurohitaruController.text = state.extraPurohitaruAmount.toInt().toString();
    if (state.guestCount > 0) {
      _guestCountController.text = state.guestCount.toString();
    }
    if (state.advanceAmount > 0) {
      _advanceAmountController.text = state.advanceAmount.toInt().toString();
    }
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _advanceAmountController.dispose();
    _extraPurohitaruController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showAddLagnaDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Lagna'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter lagna name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _lagnas.add(controller.text);
                  _selectedLagna = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  double _calculateBalance() {
    final state = ref.read(bookingWizardProvider);
    final pricing = PricingService();

    double total = state.hallPriceOverride ?? state.selectedHall?.packageRate ?? 0;

    if (state.addVadya) {
      total += state.vadyaCharge > 0 ? state.vadyaCharge : pricing.vadyaCharge;
    }

    if (_extraPurohitaruEnabled) {
      total += double.tryParse(_extraPurohitaruController.text) ?? 7000;
    }

    final advance =
        double.tryParse(_advanceAmountController.text) ?? 0;

    return total - advance;
  }

  bool _isNextEnabled() {
    return _selectedDate != null && _selectedTime != null && _selectedLagna != null;
  }

  void _onNext() {
    final extraAmt = double.tryParse(_extraPurohitaruController.text) ?? 7000;
    ref.read(bookingWizardProvider.notifier).updateMuhurthamDetails(
          date: _selectedDate,
          lagna: _selectedLagna,
          time: _selectedTime,
          guests: int.tryParse(_guestCountController.text),
          advance: double.tryParse(_advanceAmountController.text),
          extraPurohitaruEnabled: _extraPurohitaruEnabled,
          extraPurohitaruAmount: extraAmt,
          extraPurohitaru: _extraPurohitaruEnabled ? extraAmt : 0,
        );
    ref.read(bookingWizardProvider.notifier).updateMaxStep(4);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookingWizardStep4()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = ref.watch(bookingWizardProvider.select((s) => s.isEditMode));

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
          const WizardStepIndicator(totalSteps: 6, currentStep: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Muhurtham details',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Step 3 of 6',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // CARD 1: Date & Muhurtham
                  _buildSectionCard(
                    children: [
                      _buildLabel('Event date'),
                      const SizedBox(height: 5),
                      _buildPickerField(
                        text: _selectedDate == null
                            ? 'Select date'
                            : DateFormat('d MMMM yyyy').format(_selectedDate!),
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Lagna'),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._lagnas.map((lagna) => _buildLagnaChip(lagna)),
                          ActionChip(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            label: const Text('Other +'),
                            labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            onPressed: _showAddLagnaDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Muhurtham time'),
                      const SizedBox(height: 5),
                      _buildPickerField(
                        text: _selectedTime == null
                            ? 'Select time'
                            : _selectedTime!.format(context),
                        icon: Icons.access_time,
                        onTap: () => _selectTime(context),
                      ),

                      // Extra Purohitaru Section
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Extra Purohitaru',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Switch(
                            value: _extraPurohitaruEnabled,
                            onChanged: (val) {
                              setState(() {
                                _extraPurohitaruEnabled = val;
                              });
                            },
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (_extraPurohitaruEnabled) ...[
                        const SizedBox(height: 12),
                        _buildLabel('Purohitaru Rate'),
                        const SizedBox(height: 5),
                        _buildInputField(
                          controller: _extraPurohitaruController,
                          hint: 'Enter rate',
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 14),
                  
                  // CARD 2: Guests & Advance
                  _buildSectionCard(
                    children: [
                      _buildLabel('Guest count'),
                      const SizedBox(height: 5),
                      _buildInputField(
                        controller: _guestCountController,
                        hint: 'Enter guest count',
                        icon: Icons.people_outline,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Advance amount'),
                      const SizedBox(height: 5),
                      _buildInputField(
                        controller: _advanceAmountController,
                        hint: 'Enter advance amount',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        suffixText: 'Balance: ₹${_calculateBalance().toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isNextEnabled() ? _onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isEditMode ? 'Save and Continue' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPickerField({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: text.startsWith('Select') ? Colors.grey.shade400 : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 18),
            filled: true,
            fillColor: const Color(0xFFFDF7F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (suffixText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              suffixText,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildLagnaChip(String lagna) {
    final isSelected = _selectedLagna == lagna;
    return ChoiceChip(
      label: Text(lagna),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLagna = selected ? lagna : null;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}
