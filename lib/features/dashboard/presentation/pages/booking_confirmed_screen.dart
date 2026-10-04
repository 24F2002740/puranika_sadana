import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:puranika_sadana/core/constants/app_colors.dart';
import 'package:puranika_sadana/core/constants/app_dimensions.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/booking_wizard_provider.dart';
import 'package:puranika_sadana/features/dashboard/presentation/widgets/wizard_step_indicator.dart';
import 'receipt_preview_screen.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final BookingWizardState bookingState;

  const BookingConfirmedScreen({
    super.key,
    required this.bookingId,
    required this.bookingState,
  });

  @override
  Widget build(BuildContext context) {
    final String eventDate = bookingState.eventDate != null
        ? DateFormat('dd MMM yyyy').format(bookingState.eventDate!)
        : 'N/A';
    
    final String muhurthamTime = bookingState.muhurthamTime != null
        ? bookingState.muhurthamTime!.format(context)
        : 'N/A';

    // Use the total amount directly from the wizard state as it includes all services
    final double totalAmount = bookingState.totalAmount;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF7A1818), // Secondary maroon
              AppColors.primary, // Dark maroon
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const WizardStepIndicator(
                totalSteps: 6, 
                currentStep: 6,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      const Text(
                        'Booking Confirmed!',
                        style: TextStyle(
                          color: Color(0xFFFBF7EE),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Thank you for choosing Puranika Sadana',
                        style: TextStyle(
                          color: Color(0xCCFBF7EE),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: Text(
                          bookingId,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.l),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF7EE),
                          borderRadius: BorderRadius.circular(AppRadius.l),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: Text(
                                    bookingState.selectedHall?.name ?? 'Hall Name',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.m),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: Text(
                                    '$eventDate • Muhurtham $muhurthamTime',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                              child: Divider(color: Color(0xFFE7DCC4), thickness: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(totalAmount)}', 
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReceiptPreviewScreen(isReadOnly: true),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBF7EE),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'View Receipt',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            context.go('/dashboard');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(color: AppColors.gold, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                          ),
                          child: const Text(
                            'Back to Dashboard',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
