import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/booking_status.dart';
import '../../domain/models/hall.dart';
import '../providers/bookings_provider.dart';
import '../providers/booking_wizard_provider.dart';
import '../../data/repositories/booking_repository_provider.dart';
import '../../data/repositories/hall_repository_provider.dart';
import '../../../../core/services/receipt_generator.dart';
import '../widgets/status_pill.dart';
import '../widgets/dashboard_bottom_navigation.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  Hall? _hallFilter;
  String _dateFilter = 'All Time';
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final hallsAsync = ref.watch(watchHallsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7F0),
        body: Column(
          children: [
            _buildHeader(hallsAsync.value ?? []),
            _buildTabBar(),
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingList(bookings, 'All'),
                      _buildBookingList(bookings, 'Upcoming'),
                      _buildBookingList(bookings, 'Completed'),
                      _buildBookingList(bookings, 'Cancelled'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/new-booking'),
          backgroundColor: const Color(0xFF3D1608),
          child: const Icon(Icons.add, color: Color(0xFFE5D1B2)),
        ),
        bottomNavigationBar: const DashboardBottomNavigation(),
      ),
    );
  }

  Widget _buildHeader(List<Hall> halls) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bookings',
                    style: TextStyle(
                      color: Color(0xFFE5D1B2),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Puranika Sadana',
                    style: TextStyle(
                      color: const Color(0xFFE5D1B2).withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => context.push('/new-booking'),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFE5D1B2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name, ID, phone...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: _hallFilter?.name ?? 'All Halls',
                  onTap: () => _showHallFilter(halls),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _dateFilter,
                  onTap: _showDateFilter,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Sort: $_sortBy',
                  onTap: _showSortFilter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFFE5D1B2), fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: const Color(0xFFE5D1B2).withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: const Color(0xFFB5651D),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFB5651D),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Upcoming'),
          Tab(text: 'Completed'),
          Tab(text: 'Cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String statusTab) {
    var filteredList = _filterAndSortBookings(bookings, statusTab);

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No bookings found', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        return _BookingListItem(
          booking: filteredList[index],
          onView: () => context.push('/booking-details/${filteredList[index].id}'),
          onEdit: () => _editBooking(filteredList[index]),
          onPrint: () => _printBooking(filteredList[index]),
          onCancel: () => _confirmCancel(filteredList[index]),
        );
      },
    );
  }

  List<Booking> _filterAndSortBookings(List<Booking> bookings, String statusTab) {
    var list = bookings.where((b) {
      // Status Tab Filter
      bool matchesTab = true;
      if (statusTab == 'Upcoming') {
        matchesTab = b.status == BookingStatus.upcoming || b.status == BookingStatus.confirmed || b.status == BookingStatus.pending;
      } else if (statusTab == 'Completed') {
        matchesTab = b.status == BookingStatus.completed;
      } else if (statusTab == 'Cancelled') {
        matchesTab = b.status == BookingStatus.cancelled;
      }

      // Search Filter
      final matchesSearch = b.groomName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.brideName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.contact1.contains(_searchQuery) ||
          b.id.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Hall Filter
      final matchesHall = _hallFilter == null || b.hall.id == _hallFilter?.id;

      // Date Filter
      bool matchesDate = true;
      final now = DateTime.now();
      if (_dateFilter == 'This Month') {
        matchesDate = b.eventDate.month == now.month && b.eventDate.year == now.year;
      } else if (_dateFilter == 'Today') {
        matchesDate = b.eventDate.day == now.day && b.eventDate.month == now.month && b.eventDate.year == now.year;
      }

      return matchesTab && matchesSearch && matchesHall && matchesDate;
    }).toList();

    // Sorting
    if (_sortBy == 'Newest') {
      list.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    } else if (_sortBy == 'Oldest') {
      list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    } else if (_sortBy == 'Amount') {
      list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }

    return list;
  }

  void _showHallFilter(List<Hall> halls) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Select Hall', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            title: const Text('All Halls'),
            onTap: () {
              setState(() => _hallFilter = null);
              Navigator.pop(context);
            },
          ),
          ...halls.map((h) => ListTile(
            title: Text(h.name),
            onTap: () {
              setState(() => _hallFilter = h);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  void _showDateFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Select Period', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(title: const Text('All Time'), onTap: () { setState(() => _dateFilter = 'All Time'); Navigator.pop(context); }),
          ListTile(title: const Text('Today'), onTap: () { setState(() => _dateFilter = 'Today'); Navigator.pop(context); }),
          ListTile(title: const Text('This Month'), onTap: () { setState(() => _dateFilter = 'This Month'); Navigator.pop(context); }),
        ],
      ),
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(title: const Text('Newest First'), onTap: () { setState(() => _sortBy = 'Newest'); Navigator.pop(context); }),
          ListTile(title: const Text('Oldest First'), onTap: () { setState(() => _sortBy = 'Oldest'); Navigator.pop(context); }),
          ListTile(title: const Text('Highest Amount'), onTap: () { setState(() => _sortBy = 'Amount'); Navigator.pop(context); }),
        ],
      ),
    );
  }

  void _editBooking(Booking booking) {
    ref.read(bookingWizardProvider.notifier).reset();
    ref.read(bookingWizardProvider.notifier).initFromBooking(booking);
    context.push('/new-booking');
  }

  Future<void> _printBooking(Booking booking) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmCancel(Booking booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFBF7EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Cancel Booking', style: TextStyle(color: Color(0xFF3D1608), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel the booking for ${booking.brideName} & ${booking.groomName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('NO', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final repository = ref.read(bookingRepositoryProvider);
              await repository.updateBooking(booking.copyWith(status: BookingStatus.cancelled));
              
              // Cancel scheduled reminders
              await NotificationService().cancelBookingReminders(booking.id);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking cancelled successfully')),
                  );
                }
              }
            },
            child: const Text('YES, CANCEL', style: TextStyle(color: Color(0xFF3D1608), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _BookingListItem extends StatelessWidget {
  final Booking booking;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onCancel;

  const _BookingListItem({
    required this.booking,
    required this.onView,
    required this.onEdit,
    required this.onPrint,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final balance = booking.totalAmount - booking.advancePaid;
    final isFullyPaid = balance <= 0;
    final isCancelled = booking.status == BookingStatus.cancelled;
    final isCompleted = booking.status == BookingStatus.completed;

    return GestureDetector(
      onTap: onView, // BUG 4 Fix: Entire card is now clickable to View
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: ID and Status
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${booking.id.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StatusPill(status: booking.status),
                ],
              ),
            ),
            // Names
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${booking.brideName} & ${booking.groomName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D1608),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Hall and Date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.business_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    booking.hall.name,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(booking.eventDate),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Amount Summary Box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${NumberFormat('#,##,###').format(booking.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balance Due', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          balance > 0 ? '₹${NumberFormat('#,##,###').format(balance)}' : '—',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Payment Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isFullyPaid ? const Color(0xFF7FAE5B) : const Color(0xFFB5651D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFullyPaid ? 'Fully Paid' : (booking.advancePaid > 0 ? 'Partially Paid' : 'Pending'),
                    style: TextStyle(
                      color: isFullyPaid ? const Color(0xFF7FAE5B) : const Color(0xFFB5651D),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCompleted) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (booking.certificateIssued) {
                          context.push('/marriage-certificate', extra: booking);
                        } else {
                          context.push('/aadhaar-scan', extra: booking);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: booking.certificateIssued
                              ? const Color(0xFF7FAE5B).withValues(alpha: 0.1)
                              : const Color(0xFFBA7517).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: booking.certificateIssued
                                ? const Color(0xFF7FAE5B)
                                : const Color(0xFFBA7517),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              booking.certificateIssued ? Icons.verified : Icons.card_membership,
                              size: 14,
                              color: booking.certificateIssued
                                  ? const Color(0xFF7FAE5B)
                                  : const Color(0xFFBA7517),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.certificateIssued ? 'Certificate Issued' : 'Certificate',
                              style: TextStyle(
                                color: booking.certificateIssued
                                    ? const Color(0xFF7FAE5B)
                                    : const Color(0xFFBA7517),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(child: _buildButton('View', const Color(0xFF3D1608), Colors.white, onView)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildButton('Edit', Colors.white, Colors.black87, onEdit, showBorder: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildButton('Print', Colors.white, Colors.black87, onPrint, showBorder: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildButton('Cancel', Colors.white, const Color(0xFFA53D30), onCancel, showBorder: true, isDisabled: isCancelled || isCompleted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, Color bgColor, Color textColor, VoidCallback onTap, {bool showBorder = false, bool isDisabled = false}) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: showBorder ? Border.all(color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade300) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDisabled ? Colors.grey.shade400 : textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
