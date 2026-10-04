import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/booking_wizard_provider.dart';
import 'wizard_step_indicator.dart';
import 'booking_wizard_step2.dart';

class BookingWizardStep1 extends ConsumerStatefulWidget {
  const BookingWizardStep1({super.key});

  @override
  ConsumerState<BookingWizardStep1> createState() => _BookingWizardStep1State();
}

class _BookingWizardStep1State extends ConsumerState<BookingWizardStep1> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _groomNameController;
  late TextEditingController _groomJaatiController;
  late TextEditingController _brideNameController;
  late TextEditingController _brideJaatiController;
  late TextEditingController _contact1Controller;
  late TextEditingController _contact2Controller;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingWizardProvider);
    _groomNameController = TextEditingController(text: state.groomName);
    _groomJaatiController = TextEditingController(text: state.groomJaati);
    _brideNameController = TextEditingController(text: state.brideName);
    _brideJaatiController = TextEditingController(text: state.brideJaati);
    _contact1Controller = TextEditingController(text: state.contact1);
    _contact2Controller = TextEditingController(text: state.contact2);
    _addressController = TextEditingController(text: state.address);
  }

  @override
  void dispose() {
    _groomNameController.dispose();
    _groomJaatiController.dispose();
    _brideNameController.dispose();
    _brideJaatiController.dispose();
    _contact1Controller.dispose();
    _contact2Controller.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(bookingWizardProvider.notifier).updateGroomDetails(_groomNameController.text, _groomJaatiController.text);
      ref.read(bookingWizardProvider.notifier).updateBrideDetails(_brideNameController.text, _brideJaatiController.text);
      ref.read(bookingWizardProvider.notifier).updateContactInfo(_contact1Controller.text, _contact2Controller.text, _addressController.text);
      ref.read(bookingWizardProvider.notifier).updateMaxStep(2);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BookingWizardStep2(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          const WizardStepIndicator(totalSteps: 6, currentStep: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.customerDetails,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Step 1 of 6',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // SECTION 1: Groom details
                    _buildSectionCard(
                      title: 'Groom details',
                      icon: Icons.person,
                      children: [
                        _buildLabelledField(
                          label: 'Groom name',
                          controller: _groomNameController,
                          hint: 'Enter groom name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildLabelledField(
                          label: 'Jaati / caste',
                          controller: _groomJaatiController,
                          hint: 'Enter jaati / caste',
                          icon: Icons.star_outline,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),

                    // SECTION 2: Bride details
                    _buildSectionCard(
                      title: 'Bride details',
                      icon: Icons.person,
                      children: [
                        _buildLabelledField(
                          label: 'Bride name',
                          controller: _brideNameController,
                          hint: 'Enter bride name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildLabelledField(
                          label: 'Jaati / caste',
                          controller: _brideJaatiController,
                          hint: 'Enter jaati / caste',
                          icon: Icons.star_outline,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // SECTION 3: Contact and address
                    _buildSectionCard(
                      title: 'Contact and address',
                      icon: Icons.phone_in_talk,
                      children: [
                        _buildLabelledField(
                          label: 'Contact number 1',
                          controller: _contact1Controller,
                          hint: 'Enter contact number 1',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildLabelledField(
                          label: 'Contact number 2',
                          controller: _contact2Controller,
                          hint: 'Enter contact number 2',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildLabelledField(
                          label: 'Native place / address',
                          controller: _addressController,
                          hint: 'Enter native place / address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          
          // Next Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF7A1818),
                    AppColors.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isEditMode ? 'Save and Continue' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.gold, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabelledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
