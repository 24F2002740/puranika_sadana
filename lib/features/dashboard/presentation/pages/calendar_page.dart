import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/booking_status.dart';
import '../../domain/models/hall.dart';
import '../providers/bookings_provider.dart';
import '../providers/booking_wizard_provider.dart';
import '../../data/repositories/booking_repository_provider.dart';
import '../../data/repositories/hall_repository_provider.dart';
import '../widgets/dashboard_bottom_navigation.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
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
        backgroundColor: const Color(0xFFFBF7EE),
        body: bookingsAsync.when(
          data: (allBookings) => hallsAsync.when(
            data: (halls) => Column(
              children: [
                _buildHeader(),
                _buildCalendarGrid(allBookings),
                Expanded(
                  child: _buildAgendaSection(allBookings, halls),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        bottomNavigationBar: const DashboardBottomNavigation(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF3D1608),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Text(
            'Tap a date to view or book',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavBtn(Icons.chevron_left, () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                });
              }),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildNavBtn(Icons.chevron_right, () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                });
              }),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Available',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(width: 16),
              _buildLegend(
                const LinearGradient(
                  colors: [Color(0xFF3EC6A0), Color(0xFF56CCF2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                '1 hall',
              ),
              const SizedBox(width: 16),
              _buildLegend(
                const LinearGradient(
                  colors: [Color(0xFFFF5E62), Color(0xFFC81D4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                'Both',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildLegend(Gradient gradient, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(List<Booking> allBookings) {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startOffset = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isPast = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

              final dayBookings = allBookings.where((b) => 
                DateUtils.isSameDay(b.eventDate, date) && 
                b.status != BookingStatus.cancelled
              ).toList();
              
              final bookedHalls = dayBookings.map((b) => b.hall.id).toSet();
              final bookedCount = bookedHalls.length;

              BoxDecoration? decoration;
              Color textColor = const Color(0xFF3D1608);

              if (!isPast) {
                if (bookedCount == 1) {
                  decoration = BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3EC6A0), Color(0xFF56CCF2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3EC6A0).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  );
                  textColor = const Color(0xFF04352E);
                } else if (bookedCount >= 2) {
                  decoration = BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF5E62), Color(0xFFC81D4B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC81D4B).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  );
                  textColor = Colors.white;
                }

                if (isSelected) {
                  decoration = BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: decoration?.gradient,
                    boxShadow: decoration?.boxShadow,
                    border: Border.all(color: const Color(0xFF5D1014), width: 2),
                  );
                }
              }

              return GestureDetector(
                onTap: isPast ? null : () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: decoration,
                  child: Center(
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey.shade300 : textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaSection(List<Booking> allBookings, List<Hall> halls) {
    final dayBookings = allBookings.where((b) => 
      DateUtils.isSameDay(b.eventDate, _selectedDate) && 
      b.status != BookingStatus.cancelled
    ).toList();

    final bookedHalls = dayBookings.map((b) => b.hall.id).toSet();
    final activeHalls = halls.where((h) => h.isActive).toList();
    
    String summary = 'All halls available';
    if (dayBookings.isNotEmpty) {
      if (bookedHalls.length < activeHalls.length) {
        summary = '${activeHalls.length - bookedHalls.length} hall(s) available';
      } else {
        summary = 'All halls booked';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32, color: Color(0xFFE7DCC4)),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D1608),
            ),
          ),
          Text(
            summary,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ...activeHalls.map((hall) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildHallSection(hall, dayBookings),
          )),
        ],
      ),
    );
  }

  Widget _buildHallSection(Hall hall, List<Booking> dayBookings) {
    final hallBookings = dayBookings.where((b) => b.hall.id == hall.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hall.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        if (hallBookings.isEmpty)
          _buildEmptyHallCard(hall)
        else
          ...hallBookings.map((b) => _buildBookingAgendaCard(b)),
      ],
    );
  }

  Widget _buildEmptyHallCard(Hall hall) {
    return InkWell(
      onTap: () {
        ref.read(bookingWizardProvider.notifier).reset();
        ref.read(bookingWizardProvider.notifier).updateHallSelection(hall, false);
        ref.read(bookingWizardProvider.notifier).updateMuhurthamDetails(date: _selectedDate);
        context.push('/new-booking');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFAF2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7DCC4), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: const Color(0xFFB5651D).withValues(alpha: 0.5),
              size: 28,
            ),
            const SizedBox(height: 8),
            const Text(
              '+ Book this hall',
              style: TextStyle(
                color: Color(0xFFB5651D),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingAgendaCard(Booking booking) {
    final startTimeStr = booking.startTime != null 
        ? DateFormat.jm().format(DateTime(2022, 1, 1, booking.startTime!.hour, booking.startTime!.minute)) 
        : '10:00 AM';
    final endTimeStr = booking.endTime != null 
        ? DateFormat.jm().format(DateTime(2022, 1, 1, booking.endTime!.hour, booking.endTime!.minute)) 
        : '3:00 PM';
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${booking.brideName} & ${booking.groomName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D1608),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7FAE5B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Booked',
                  style: TextStyle(
                    color: Color(0xFF7FAE5B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$startTimeStr – $endTimeStr',
            style: const TextStyle(
              color: Color(0xFFB5651D),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${booking.guestCount} guests',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '#${booking.id}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn('View', isPrimary: true, onTap: () {
                  context.push('/booking-details/${booking.id}');
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionBtn('Cancel', isNegative: true, onTap: () => _confirmCancel(booking)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, {bool isPrimary = false, bool isNegative = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF3D1608) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isNegative 
                ? const Color(0xFFA53D30).withValues(alpha: 0.3)
                : (isPrimary ? const Color(0xFF3D1608) : const Color(0xFFE7DCC4)),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isNegative 
                  ? const Color(0xFFA53D30) 
                  : (isPrimary ? Colors.white : const Color(0xFF3D1608)),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmCancel(Booking booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFBF7EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Cancel Booking',
          style: TextStyle(color: Color(0xFF3D1608), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Cancel booking for ${booking.brideName} & ${booking.groomName}? This will free up the date for other bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('BACK', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final repository = ref.read(bookingRepositoryProvider);
              await repository.updateBooking(booking.copyWith(status: BookingStatus.cancelled));
              
              // Cancel notifications
              await NotificationService().cancelBookingReminders(booking.id);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled successfully'),
                      backgroundColor: Color(0xFFA53D30),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'YES, CANCEL',
              style: TextStyle(color: Color(0xFFA53D30), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
