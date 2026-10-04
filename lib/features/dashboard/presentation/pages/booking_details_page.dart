import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/booking.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/booking_status.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/booking_wizard_provider.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/bookings_provider.dart';
import 'package:puranika_sadana/core/services/receipt_generator.dart';
import 'package:puranika_sadana/core/services/pricing_service.dart';
import 'package:puranika_sadana/features/dashboard/presentation/pages/receipt_preview_screen.dart';
import 'package:puranika_sadana/features/dashboard/presentation/pages/collect_balance_page.dart';
import 'package:puranika_sadana/features/dashboard/data/repositories/booking_repository_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingDetailsPage extends ConsumerStatefulWidget {
  final String bookingId;
  final int initialTab;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _notesController;
  Timer? _debounce;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNotesChanged(String value, Booking booking) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _saveNotes(value, booking);
    });
  }

  Future<void> _saveNotes(String notes, Booking booking) async {
    setState(() => _isSaving = true);
    final repository = ref.read(bookingRepositoryProvider);
    await repository.updateBooking(booking.copyWith(notes: notes));
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes saved successfully'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          width: 200,
          backgroundColor: Color(0xFF7FAE5B),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  void _editBooking(Booking booking) {
    ref.read(bookingWizardProvider.notifier).reset();
    ref.read(bookingWizardProvider.notifier).initFromBooking(booking);
    context.push('/new-booking');
  }

  void _completePayment(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CollectBalancePage(booking: booking)),
    );
  }

  Future<void> _printReceipt(Booking booking) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating receipt...')));
    
    final wizardState = BookingWizardState.fromBooking(booking);
    
    try {
      final pdfData = await ReceiptGenerator.generate(wizardState);
      await Printing.layoutPdf(
        onLayout: (format) => pdfData,
        name: 'Receipt_${booking.id}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error printing: $e')));
      }
    }
  }

  Future<void> _shareReceipt(Booking booking) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing receipt for sharing...')));
    
    final wizardState = BookingWizardState.fromBooking(booking);
    
    try {
      final pdfData = await ReceiptGenerator.generate(wizardState);
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/Receipt_${booking.id}.pdf').create();
      await file.writeAsBytes(pdfData);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Booking Receipt for ${booking.brideName} & ${booking.groomName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  void _viewCertificate(Booking booking) {
    context.push('/marriage-certificate', extra: booking);
  }

  void _issueCertificate(Booking booking) {
    context.push('/aadhaar-scan', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final bookingIndex = bookings.indexWhere((b) => b.id == widget.bookingId);
        
        if (bookingIndex == -1) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Booking not found')),
          );
        }
        
        final booking = bookings[bookingIndex];
        
        // Update notes controller if it was empty and we now have data
        if (_notesController.text.isEmpty && (booking.notes?.isNotEmpty ?? false)) {
            _notesController.text = booking.notes!;
        }
        
        final balance = booking.totalAmount - booking.advancePaid;
        final isFullyPaid = balance <= 0;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF7EE),
          body: Column(
            children: [
              _buildHeader(booking),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(booking, balance, isFullyPaid),
                    _buildCateringTab(booking),
                    _buildPaymentsTab(booking),
                    _buildReceiptTab(booking),
                    _buildNotesTab(booking),
                  ],
                ),
              ),
              _buildBottomActionBar(booking, isFullyPaid),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildHeader(Booking booking) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 50, 20, 20),
      color: const Color(0xFF3D1608),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '#${booking.id}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              _buildStatusBadge(booking.status),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(
              '${booking.brideName} & ${booking.groomName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toDisplayString().toUpperCase(),
        style: TextStyle(color: status.color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFFB5651D),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFB5651D),
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Catering'),
          Tab(text: 'Payments'),
          Tab(text: 'Receipt'),
          Tab(text: 'Notes'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Booking booking, double balance, bool isFullyPaid) {
    final currencyFormat = NumberFormat('#,##,###');
    final subtotal = booking.subtotal > 0 ? booking.subtotal : (booking.totalAmount - booking.additionalGuestsCharge) + booking.hallDiscount + booking.cateringDiscount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard('Customer Details', [
            _buildDetailRow(Icons.person_outline, 'Bride', booking.brideName),
            _buildDetailRow(Icons.person_outline, 'Groom', booking.groomName),
            _buildDetailRow(Icons.phone_outlined, 'Phone', booking.contact1),
            _buildDetailRow(Icons.location_on_outlined, 'Address', booking.address),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard('Hall Details', [
            _buildDetailRow(Icons.business_rounded, 'Hall Name', booking.hall.name),
            _buildDetailRow(Icons.people_outline, 'Guest Count', '${booking.guestCount} guests'),
            _buildDetailRow(Icons.calendar_today, 'Date', DateFormat('dd MMM yyyy').format(booking.eventDate)),
            _buildDetailRow(
              Icons.access_time, 
              'Time', 
              '${booking.startTime?.format(context) ?? 'N/A'} - ${booking.endTime?.format(context) ?? 'N/A'}'
            ),
            _buildDetailRow(Icons.wb_sunny_outlined, 'Muhurtham', booking.lagna ?? 'N/A'),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard('Balance Summary', [
            if (booking.hallCharge > 0) _buildAmountRow('Hall Rental', booking.hallCharge),
            if (booking.addPreviousDayHall && booking.previousDayHallAmount > 0)
              _buildAmountRow('Previous Day Hall', booking.previousDayHallAmount),
            if (booking.addVadya) _buildAmountRow('Vadya (Band)', booking.vadyaCharge),
            if (booking.extraPurohitaru > 0) _buildAmountRow('Extra Purohitaru', booking.extraPurohitaru),
            if (booking.utaRequired && booking.cateringTotal > 0) 
              _buildAmountRow('Catering ${booking.cateringTier > 0 ? "(Tier ${booking.cateringTier})" : "(Manual)"}', booking.cateringTotal),
            if (booking.addBeligeTindi && booking.beligeTindiAmount > 0)
              _buildAmountRow('Breakfast (Belige Tindi)', booking.beligeTindiAmount),
            if (booking.addSanjeTindi && booking.sanjeTindiAmount > 0)
              _buildAmountRow('Evening Snacks (Sanje Tindi)', booking.sanjeTindiAmount),
            if (booking.addRatriUta && booking.ratriUtaAmount > 0)
              _buildAmountRow('Dinner (Ratri Uta)', booking.ratriUtaAmount),
            if (booking.drinkEnabled && booking.drinkTotalAmount > 0)
              _buildAmountRow(booking.drinkName, booking.drinkTotalAmount),
            if (booking.addCleaning) _buildAmountRow('Cleaning Charge', booking.cleaningCharge),
            
            for (var extra in booking.savedExtras)
               if (extra.amount != 0)
                 _buildAmountRow(extra.name, extra.amount),

            if (booking.additionalGuestsCharge > 0)
              _buildAmountRow('Additional Guests Charge', booking.additionalGuestsCharge),
            
            const Divider(height: 24, color: Color(0xFFE7DCC4)),
            _buildAmountRow('Subtotal (Total Charges)', subtotal, isBold: true),
            
            if (booking.hallDiscount > 0)
              _buildSummaryAmountRow('Hall Discount', -booking.hallDiscount, color: Colors.green),
            if (booking.cateringDiscount > 0)
              _buildSummaryAmountRow('Catering Discount', -booking.cateringDiscount, color: Colors.green),

            const Divider(height: 24, color: Color(0xFFE7DCC4)),
            _buildAmountRow('Grand Total', booking.totalAmount, isBold: true),
            _buildAmountRow('Amount Paid', booking.advancePaid),
            const Divider(height: 24, color: Color(0xFFE7DCC4)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  isFullyPaid ? 'Fully Paid' : '₹${currencyFormat.format(balance)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isFullyPaid ? const Color(0xFF7FAE5B) : const Color(0xFF3D1608),
                  ),
                ),
              ],
            ),
          ]),
          if (booking.status == BookingStatus.completed || booking.certificateIssued) ...[
            const SizedBox(height: 16),
            _buildSectionCard('Marriage Certificate', [
               if (booking.certificateIssued)
                 ElevatedButton.icon(
                    onPressed: () => _viewCertificate(booking),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('VIEW MARRIAGE CERTIFICATE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FAE5B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
               else
                 ElevatedButton.icon(
                    onPressed: () => _issueCertificate(booking),
                    icon: const Icon(Icons.card_membership_outlined),
                    label: const Text('ISSUE MARRIAGE CERTIFICATE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA7517),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryAmountRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('${amount < 0 ? "-" : ""}₹${NumberFormat('#,##,###').format(amount.abs())}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildCateringTab(Booking booking) {
    if (!booking.utaRequired) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No catering included for this booking.',
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final pricing = PricingService();
    double rate = 0;
    List<String> items = [];
    
    final isManual = booking.guestCount <= pricing.manualEntryThreshold;

    if (!isManual) {
      if (booking.cateringTier == 1) {
        rate = pricing.menu1Price;
        items = pricing.menu1Dishes;
      } else if (booking.cateringTier == 2) {
        rate = pricing.menu2Price;
        items = pricing.menu2Dishes;
      } else if (booking.cateringTier == 3) {
        rate = pricing.menu3Price;
        items = pricing.menu3Dishes;
      }
    }

    rate = booking.menuRateOverride ?? rate;
    if (booking.cateringItems.isNotEmpty) {
      items = booking.cateringItems;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard('Catering Summary', [
            _buildAmountRow('Main Catering', booking.cateringTotal),
            if (booking.cateringDiscount > 0)
              _buildSummaryAmountRow('Catering Discount', -booking.cateringDiscount, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              isManual 
                ? 'Manual lump-sum amount applied.' 
                : 'Calculated based on Tier ${booking.cateringTier} rate.',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard('Selected Menu', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isManual ? 'Menu Items' : 'Tier ${booking.cateringTier} Menu', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                if (!isManual)
                  Text('₹${rate.toInt()} / plate', style: const TextStyle(color: Color(0xFFB5651D), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No items specified', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7DCC4).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
            if (booking.addBeligeTindi && booking.beligeTindiItems.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Breakfast Items (Belige Tindi)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(booking.beligeTindiItems, style: const TextStyle(fontSize: 13, color: Color(0xFF3D1608))),
            ],
            if (booking.addSanjeTindi && booking.sanjeTindiItems.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Evening Snacks (Sanje Tindi)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(booking.sanjeTindiItems, style: const TextStyle(fontSize: 13, color: Color(0xFF3D1608))),
            ],
            if (booking.addRatriUta && booking.ratriUtaItems.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Dinner Items (Ratri Uta)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(booking.ratriUtaItems, style: const TextStyle(fontSize: 13, color: Color(0xFF3D1608))),
            ],
          ]),
          const SizedBox(height: 16),
          _buildSectionCard('Optional Extras', [
            if (booking.addPalav) _buildDetailRow(Icons.add_circle_outline, 'Palav + Salad', '₹${pricing.palavSaladPrice.toInt()}/plate'),
            if (booking.addPoori) _buildDetailRow(Icons.add_circle_outline, '2 Poori + Sagu', '₹${pricing.pooriSaguPrice.toInt()}/plate'),
            if (booking.addIceCream) _buildDetailRow(Icons.add_circle_outline, 'Ice Cream', '₹${pricing.iceCreamPrice.toInt()}/plate'),
            if (booking.addWater) _buildDetailRow(Icons.add_circle_outline, 'Water Bottle', '₹${pricing.waterBottlePrice.toInt()}/plate'),
            if (booking.addPreviousDayHall && booking.previousDayHallAmount > 0)
              _buildDetailRow(Icons.history, 'Previous Day Hall', '₹${booking.previousDayHallAmount.toInt()}'),
            if (booking.addBeligeTindi && booking.beligeTindiAmount > 0)
              _buildDetailRow(Icons.breakfast_dining, 'Breakfast (Tindi)', '₹${booking.beligeTindiAmount.toInt()}'),
            if (booking.addSanjeTindi && booking.sanjeTindiAmount > 0)
              _buildDetailRow(Icons.bakery_dining, 'Evening Snacks', '₹${booking.sanjeTindiAmount.toInt()}'),
            if (booking.addRatriUta && booking.ratriUtaAmount > 0)
              _buildDetailRow(Icons.dinner_dining, 'Dinner (Ratri Uta)', '₹${booking.ratriUtaAmount.toInt()}'),
            if (booking.addCleaning) _buildDetailRow(Icons.cleaning_services, 'Cleaning Charge', '₹${booking.cleaningCharge.toInt()}'),
            if (booking.drinkEnabled && booking.drinkTotalAmount > 0) _buildDetailRow(Icons.local_drink_outlined, booking.drinkName, '₹${booking.drinkTotalAmount.toInt()}'),
            if (!booking.addPalav && !booking.addPoori && !booking.addIceCream && !booking.addWater && !booking.addCleaning && !booking.drinkEnabled && !booking.addBeligeTindi && !booking.addSanjeTindi && !booking.addRatriUta && !booking.addPreviousDayHall)
              const Text('No optional extras selected.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(Booking booking) {
    if (booking.paymentHistory.isEmpty) {
      return const Center(child: Text('No payment history found.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: booking.paymentHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = booking.paymentHistory[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFAF2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7DCC4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF7FAE5B).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF7FAE5B), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${NumberFormat('#,##,###').format(payment.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${payment.method} Payment', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(payment.date),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptTab(Booking booking) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7DCC4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Color(0xFFB5651D)),
                  SizedBox(height: 16),
                  Text('Official Booking Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Generated on confirmation', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                final notifier = ref.read(bookingWizardProvider.notifier);
                notifier.reset();
                notifier.initFromBooking(booking);
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceiptPreviewScreen(isReadOnly: true)),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('VIEW FULL RECEIPT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D1608),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab(Booking booking) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Booking Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB5651D)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Special requests, reminders, or quirks about this booking.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7DCC4)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (val) => _onNotesChanged(val, booking),
                style: GoogleFonts.notoSansKannada(
                  fontSize: 14,
                  height: 1.6,
                  color: const Color(0xFF3D1608),
                ),
                decoration: const InputDecoration(
                  hintText: 'Type notes here (Supports Kannada & English)...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _saveNotes(_notesController.text, booking),
            icon: const Icon(Icons.save_outlined),
            label: const Text('SAVE NOTES NOW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB5651D),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Booking booking, bool isFullyPaid) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          _buildActionItem(Icons.edit_outlined, 'Edit', () => _editBooking(booking)),
          const SizedBox(width: 16),
          _buildActionItem(Icons.print_outlined, 'Print', () => _printReceipt(booking)),
          const SizedBox(width: 16),
          _buildActionItem(Icons.share_outlined, 'Share', () => _shareReceipt(booking)),
          const SizedBox(width: 20),
          if (!isFullyPaid)
            Expanded(
              child: ElevatedButton(
                onPressed: () => _completePayment(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FAE5B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('COMPLETE PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF3D1608), size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3D1608))),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFAF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: isBold ? FontWeight.bold : null)),
          Text('₹${NumberFormat('#,##,###').format(amount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 15 : 13)),
        ],
      ),
    );
  }
}
