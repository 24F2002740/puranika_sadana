import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:puranika_sadana/core/constants/app_colors.dart';
import 'package:puranika_sadana/core/constants/app_dimensions.dart';
import 'package:puranika_sadana/core/services/receipt_generator.dart';
import 'package:puranika_sadana/core/services/notification_service.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/booking_wizard_provider.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/booking_status.dart';
import '../../data/repositories/booking_repository_provider.dart';
import 'booking_confirmed_screen.dart';
import '../widgets/wizard_step_indicator.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  const ReceiptPreviewScreen({super.key, this.isReadOnly = false});

  @override
  ConsumerState<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingWizardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(widget.isReadOnly ? Icons.arrow_back : Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isReadOnly ? 'Booking Receipt' : 'Receipt Preview',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!widget.isReadOnly)
            const WizardStepIndicator(totalSteps: 6, currentStep: 5),
          Expanded(
            child: PdfPreview(
              build: (format) => ReceiptGenerator.generate(state),
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              maxPageWidth: 700,
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              pdfPreviewPageDecoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          _buildActionButtons(context, state),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingWizardState state) {
    final isEditMode = state.isEditMode;
    final repository = ref.read(bookingRepositoryProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              ),
              child: Text(
                widget.isReadOnly ? 'Close' : 'Back to Edit',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async {
                if (widget.isReadOnly) {
                  final pdfData = await ReceiptGenerator.generate(state);
                  await Printing.layoutPdf(
                    onLayout: (format) => pdfData,
                    name: 'Booking_Receipt_${state.groomName}_${state.brideName}',
                  );
                  return;
                }

                // Guard against re-entrancy
                if (_isSaving) return;

                setState(() => _isSaving = true);

                try {
                  String finalBookingId;
                  Booking finalBooking;
                  
                  // Use gross catering total (discount is saved separately)
                  final cateringTotalGross = state.utaRequired ? state.cateringTotal : 0.0;

                  if (isEditMode) {
                    finalBookingId = state.editingBookingId!;
                    final existingBooking = await repository.getBooking(finalBookingId);
                    
                    if (existingBooking != null) {
                      finalBooking = existingBooking.copyWith(
                        groomName: state.groomName,
                        groomJaati: state.groomJaati,
                        brideName: state.brideName,
                        brideJaati: state.brideJaati,
                        contact1: state.contact1,
                        contact2: state.contact2,
                        address: state.address,
                        hall: state.selectedHall!,
                        hallPriceOverride: state.hallPriceOverride,
                        hallDiscount: state.hallDiscount,
                        hallCharge: state.hallCharge,
                        eventDate: state.eventDate!,
                        startTime: state.muhurthamTime,
                        lagna: state.lagna,
                        advancePaid: state.advanceAmount,
                        totalAmount: state.totalAmount,
                        subtotal: state.subtotal,
                        menuRateOverride: state.menuRateOverride,
                        cateringDiscount: state.cateringDiscount,
                        guestCount: state.guestCount,
                        cateringTier: state.selectedMenuTier ?? 2,
                        utaRequired: state.utaRequired,
                        cateringTotal: cateringTotalGross,
                        utaAmount: state.utaAmount,
                        cateringItems: state.cateringItems,
                        addVadya: state.addVadya,
                        vadyaCharge: state.vadyaCharge,
                        addPalav: state.addPalav,
                        addPoori: state.addPoori,
                        addIceCream: state.addIceCream,
                        addWater: state.addWater,
                        addCleaning: state.addCleaning,
                        cleaningCharge: state.cleaningCharge,
                        extraPurohitaruEnabled: state.extraPurohitaruEnabled,
                        extraPurohitaruAmount: state.extraPurohitaruAmount,
                        extraPurohitar: state.extraPurohitaru,
                        addPreviousDayHall: state.addPreviousDayHall,
                        previousDayHallAmount: state.previousDayHallAmount,
                        addBeligeTindi: state.addBeligeTindi,
                        beligeTindiGuestCount: state.beligeTindiGuestCount,
                        beligeTindiItems: state.beligeTindiItems,
                        beligeTindiAmount: state.beligeTindiAmount,
                        addSanjeTindi: state.addSanjeTindi,
                        sanjeTindiGuestCount: state.sanjeTindiGuestCount,
                        sanjeTindiItems: state.sanjeTindiItems,
                        sanjeTindiAmount: state.sanjeTindiAmount,
                        addRatriUta: state.addRatriUta,
                        ratriUtaGuestCount: state.ratriUtaGuestCount,
                        ratriUtaItems: state.ratriUtaItems,
                        ratriUtaAmount: state.ratriUtaAmount,
                        drinkEnabled: state.drinkEnabled,
                        drinkName: state.drinkName,
                        drinkMemberCount: state.drinkMemberCount,
                        drinkTotalAmount: state.drinkTotalAmount,
                        savedExtras: state.savedExtras,
                        customExtras: state.customExtras.map((e) => e.toBookingExtra()).toList(),
                      );
                      
                      await repository.updateBooking(finalBooking);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Booking updated successfully")),
                        );
                      }
                    } else {
                      setState(() => _isSaving = false);
                      return;
                    }
                  } else {
                    finalBooking = Booking(
                      id: '', // Will be updated by repository
                      groomName: state.groomName,
                      groomJaati: state.groomJaati,
                      brideName: state.brideName,
                      brideJaati: state.brideJaati,
                      contact1: state.contact1,
                      contact2: state.contact2,
                      address: state.address,
                      hall: state.selectedHall!,
                      hallPriceOverride: state.hallPriceOverride,
                      hallDiscount: state.hallDiscount,
                      hallCharge: state.hallCharge,
                      eventDate: state.eventDate!,
                      startTime: state.muhurthamTime,
                      lagna: state.lagna,
                      status: BookingStatus.confirmed,
                      advancePaid: state.advanceAmount,
                      totalAmount: state.totalAmount,
                      subtotal: state.subtotal,
                      menuRateOverride: state.menuRateOverride,
                      cateringDiscount: state.cateringDiscount,
                      guestCount: state.guestCount,
                      cateringTier: state.selectedMenuTier ?? 2,
                      utaRequired: state.utaRequired,
                      cateringTotal: cateringTotalGross,
                      utaAmount: state.utaAmount,
                      cateringItems: state.cateringItems,
                      addVadya: state.addVadya,
                      vadyaCharge: state.vadyaCharge,
                      addPalav: state.addPalav,
                      addPoori: state.addPoori,
                      addIceCream: state.addIceCream,
                      addWater: state.addWater,
                      addCleaning: state.addCleaning,
                      cleaningCharge: state.cleaningCharge,
                      extraPurohitaruEnabled: state.extraPurohitaruEnabled,
                      extraPurohitaruAmount: state.extraPurohitaruAmount,
                      extraPurohitaru: state.extraPurohitaru,
                      addPreviousDayHall: state.addPreviousDayHall,
                      previousDayHallAmount: state.previousDayHallAmount,
                      addBeligeTindi: state.addBeligeTindi,
                      beligeTindiGuestCount: state.beligeTindiGuestCount,
                      beligeTindiItems: state.beligeTindiItems,
                      beligeTindiAmount: state.beligeTindiAmount,
                      addSanjeTindi: state.addSanjeTindi,
                      sanjeTindiGuestCount: state.sanjeTindiGuestCount,
                      sanjeTindiItems: state.sanjeTindiItems,
                      sanjeTindiAmount: state.sanjeTindiAmount,
                      addRatriUta: state.addRatriUta,
                      ratriUtaGuestCount: state.ratriUtaGuestCount,
                      ratriUtaItems: state.ratriUtaItems,
                      ratriUtaAmount: state.ratriUtaAmount,
                      drinkEnabled: state.drinkEnabled,
                      drinkName: state.drinkName,
                      drinkMemberCount: state.drinkMemberCount,
                      drinkTotalAmount: state.drinkTotalAmount,
                      savedExtras: state.savedExtras,
                      customExtras: state.customExtras.map((e) => e.toBookingExtra()).toList(),
                      paymentHistory: state.advanceAmount > 0 
                        ? [PaymentEntry(date: DateTime.now(), method: state.paymentMethod, amount: state.advanceAmount)]
                        : [],
                    );
                    
                    finalBookingId = await repository.createBooking(finalBooking);
                    finalBooking = finalBooking.copyWith(id: finalBookingId);
                  }

                  // Schedule notifications for the confirmed/updated booking
                  await NotificationService().scheduleBookingReminders(finalBooking);

                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingConfirmedScreen(
                          bookingId: finalBooking.id,
                          bookingState: state,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) setState(() => _isSaving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error saving booking: $e")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  else
                    Icon(widget.isReadOnly ? Icons.print_rounded : Icons.check_circle_outline, size: 18),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    _isSaving 
                        ? 'Saving...' 
                        : (widget.isReadOnly 
                            ? 'Print Receipt' 
                            : (isEditMode ? 'Save Changes' : 'Confirm & Save')),
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
