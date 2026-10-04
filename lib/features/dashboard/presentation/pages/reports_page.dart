import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:go_router/go_router.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/booking_status.dart';
import '../providers/bookings_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Month', 'Last Month', 'This Year', 'Custom'];

  List<Booking> _getFilteredBookings(List<Booking> allBookings) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedPeriod) {
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(now.year - 10, 1, 1);
    }

    return allBookings.where((b) => 
      b.eventDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
      b.eventDate.isBefore(end.add(const Duration(seconds: 1))) &&
      b.status != BookingStatus.cancelled
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/dashboard');
      },
      child: bookingsAsync.when(
        data: (allBookings) {
          if (allBookings.isEmpty) {
            return Scaffold(
              backgroundColor: const Color(0xFFFBF7EE),
              appBar: _buildAppBar([]),
              body: _buildEmptyState('No bookings yet — reports will appear once bookings are added.'),
            );
          }

          final filtered = _getFilteredBookings(allBookings);

          double totalRevenue = filtered.fold(0, (sum, item) => sum + item.advancePaid);
          double pendingBalance = filtered.fold(0, (sum, item) => sum + (item.totalAmount - item.advancePaid));
          int totalBookings = filtered.length;

          int bigHallCount = filtered.where(
                (b) => b.hall.name == 'Puranika Sabha Sadana',
          ).length;

          int smallHallCount = filtered.where(
                (b) => b.hall.name == 'Puranika Sadana',
          ).length;

          String mostBookedHall = 'None';

          if (totalBookings > 0) {
            if (bigHallCount > smallHallCount) {
              mostBookedHall = 'Puranika Sabha Sadana';
            } else if (smallHallCount > bigHallCount) {
              mostBookedHall = 'Puranika Sadana';
            } else {
              mostBookedHall = 'Equal';
            }
          }

          return Scaffold(
            backgroundColor: const Color(0xFFFBF7EE),
            appBar: _buildAppBar(filtered),
            body: Column(
              children: [
                _buildPeriodFilters(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryStats(totalRevenue, totalBookings, pendingBalance, mostBookedHall),
                        const SizedBox(height: 24),
                        _buildRevenueChart(allBookings),
                        const SizedBox(height: 24),
                        _buildHallComparison(bigHallCount, smallHallCount, totalBookings),
                        const SizedBox(height: 24),
                        _buildPendingBalances(filtered),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }

  AppBar _buildAppBar(List<Booking> filtered) {
    return AppBar(
      backgroundColor: const Color(0xFF3D1608),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/dashboard'),
      ),
      title: const Text('Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        if (filtered.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _showExportOptions(context, filtered),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 80, color: const Color(0xFF3D1608).withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Insufficient Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3D1608).withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilters() {
    return Container(
      height: 60,
      color: const Color(0xFF3D1608),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = _selectedPeriod == period;
          return ChoiceChip(
            label: Text(
              period,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFE7DCC4),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedPeriod = period),
            selectedColor: const Color(0xFFB5651D),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFE7DCC4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildSummaryStats(double revenue, int bookings, double pending, String hall) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Total Revenue', '₹${NumberFormat('#,##,###').format(revenue)}', '+0% from last month', const Color(0xFF7FAE5B)),
        _buildStatCard('Total Bookings', bookings.toString(), 'In current period', const Color(0xFFB5651D)),
        _buildStatCard('Pending Balance', '₹${NumberFormat('#,##,###').format(pending)}', 'Accounts unpaid', const Color(0xFFA53D30)),
        _buildStatCard('Most Booked', hall, 'Trending this period', const Color(0xFF3D1608)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String trend, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
          Text(trend, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<Booking> allBookings) {
    final now = DateTime.now();
    List<Map<String, dynamic>> chartData = [];
    double maxRevenue = 0;

    for (int i = 5; i >= 0; i--) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      String monthLabel = DateFormat('MMM').format(monthDate);
      
      double monthlyRevenue = allBookings
          .where((b) => b.eventDate.year == monthDate.year && b.eventDate.month == monthDate.month && b.status != BookingStatus.cancelled)
          .fold(0.0, (sum, b) => sum + b.advancePaid);
      
      if (monthlyRevenue > maxRevenue) maxRevenue = monthlyRevenue;
      chartData.add({'label': monthLabel, 'value': monthlyRevenue});
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Revenue (Last 6 Months)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 30),
          if (maxRevenue == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No revenue data for the last 6 months', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chartData.map((data) {
                  double factor = maxRevenue == 0 ? 0 : data['value'] / maxRevenue;
                  String displayValue = data['value'] >= 1000 
                      ? '${(data['value'] / 1000).toStringAsFixed(1)}k'
                      : data['value'].toStringAsFixed(0);
                  return _buildBar(data['label'], factor, displayValue);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double heightFactor, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB5651D))),
        const SizedBox(height: 8),
        Container(
          width: 24,
          height: (100 * heightFactor).clamp(2, 100),
          decoration: const BoxDecoration(
            color: Color(0xFF3D1608),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHallComparison(int big, int small, int total) {
    double bigWidth = total == 0 ? 0 : big / total;
    double smallWidth = total == 0 ? 0 : small / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bookings by Hall', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          _buildHallBar('Sabha Sadana', big, bigWidth, const Color(0xFF3D1608)),
          const SizedBox(height: 12),
          _buildHallBar('P. Sadana', small, smallWidth, const Color(0xFFB5651D)),
        ],
      ),
    );
  }

  Widget _buildHallBar(String name, int count, double factor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 12)),
            Text('$count bookings', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: factor,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBalances(List<Booking> filtered) {
    final pending = filtered.where((b) => (b.totalAmount - b.advancePaid) > 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Balances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            const Text('No pending balances found.', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ...pending.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${b.brideName} & ${b.groomName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(b.id, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('₹${NumberFormat('#,###').format(b.totalAmount - b.advancePaid)}', 
                    style: const TextStyle(color: Color(0xFFA53D30), fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context, List<Booking> filtered) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF7EE),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Export Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D1608))),
            const SizedBox(height: 20),
            _buildExportTile(Icons.payments_outlined, 'Revenue Report', () => _generateAndPrintPDF(filtered, 'Revenue')),
            _buildExportTile(Icons.event_note_outlined, 'Bookings Report', () => _generateAndPrintPDF(filtered, 'Bookings')),
            _buildExportTile(Icons.account_balance_wallet_outlined, 'Pending Balances', () => _generateAndPrintPDF(filtered, 'Pending')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3D1608)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _generateAndPrintPDF(List<Booking> bookings, String type) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Puranika Sadana - $type Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Generated on: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['ID', 'Names', 'Hall', 'Date', 'Amount', 'Paid', 'Balance'],
                ...bookings.map((b) => [
                  b.id,
                  '${b.brideName} & ${b.groomName}',
                  b.hall.name,
                  DateFormat('dd/MM/yy').format(b.eventDate),
                  b.totalAmount.toString(),
                  b.advancePaid.toString(),
                  (b.totalAmount - b.advancePaid).toString(),
                ]),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
