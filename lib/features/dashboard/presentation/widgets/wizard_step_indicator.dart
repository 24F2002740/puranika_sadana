import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_wizard_provider.dart';
import 'booking_wizard_step1.dart';
import 'booking_wizard_step2.dart';
import 'booking_wizard_step3.dart';
import 'booking_wizard_step4.dart';
import 'booking_wizard_step5.dart';
import '../pages/receipt_preview_screen.dart';

class WizardStepIndicator extends ConsumerWidget {
  final int totalSteps;
  final int currentStep;

  const WizardStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  void _jumpToStep(BuildContext context, int step) {
    Widget nextStep;
    switch (step) {
      case 1:
        nextStep = const BookingWizardStep1();
        break;
      case 2:
        nextStep = const BookingWizardStep2();
        break;
      case 3:
        nextStep = const BookingWizardStep3();
        break;
      case 4:
        nextStep = const BookingWizardStep4();
        break;
      case 5:
        nextStep = const BookingWizardStep5();
        break;
      case 6:
        nextStep = const ReceiptPreviewScreen();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => nextStep),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(bookingWizardProvider);
    final maxStepReached = wizardState.maxStepReached;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 30),
      color: const Color(0xFFFBF7EE),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            final stepIndex = index ~/ 2 + 1;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;
            final canNavigate = stepIndex <= maxStepReached;

            return GestureDetector(
              onTap: canNavigate && !isCurrent ? () => _jumpToStep(context, stepIndex) : null,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? const Color(0xFFE5D1B2).withValues(alpha: 0.3)
                          : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                            ? const Color(0xFF3D1608).withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '$stepIndex',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrent 
                                ? const Color(0xFF3D1608) 
                                : Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
            );
          } else {
            final stepAfterIndex = index ~/ 2 + 2;
            final isCompleted = stepAfterIndex <= currentStep;

            return Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isCompleted 
                    ? Colors.green 
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            );
          }
        }),
      ),
    );
  }
}
