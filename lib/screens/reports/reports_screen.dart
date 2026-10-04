import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:go_router/go_router.dart';
import '../../features/dashboard/domain/models/booking.dart';
import '../../core/constants/app_colors.dart';
import '../../features/reports/presentation/providers/reports_provider.dart';
import '../../services/reports_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final notifier = ref.read(reportsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportReport(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(context, state, notifier),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Error: ${state.error}'))
                    : RefreshIndicator(
                        onRefresh: () => notifier.loadReport(),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryGrid(state.summary),
                              const SizedBox(height: 24),
                              _buildBreakdownChart(context, state),
                              const SizedBox(height: 24),
                              _buildHallBreakdown(state.hallSummaries),
                              const SizedBox(height: 24),
                              _buildPendingBalances(context, state.balanceDueBookings),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ReportState state, ReportNotifier notifier) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Column(
        children: [
          SegmentedButton<ReportPeriod>(
            segments: const [
              ButtonSegment(value: ReportPeriod.daily, label: Text('Daily')),
              ButtonSegment(value: ReportPeriod.monthly, label: Text('Monthly')),
              ButtonSegment(value: ReportPeriod.yearly, label: Text('Yearly')),
            ],
            selected: {state.period},
            onSelectionChanged: (val) => notifier.setPeriod(val.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedBackgroundColor: AppColors.gold,
              selectedForegroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _selectDate(context, state, notifier),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatSelectedDate(state),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate(ReportState state) {
    switch (state.period) {
      case ReportPeriod.daily:
        return DateFormat('dd MMM yyyy').format(state.selectedDate);
      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy').format(state.selectedDate);
      case ReportPeriod.yearly:
        return DateFormat('yyyy').format(state.selectedDate);
    }
  }

  Future<void> _selectDate(BuildContext context, ReportState state, ReportNotifier notifier) async {
    if (state.period == ReportPeriod.daily) {
      final picked = await showDatePicker(
        context: context,
        initialDate: state.selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) notifier.setSelectedDate(picked);
    } else {
      // Simple month/year picker logic or dialog
      // For brevity, using a simple year picker for Yearly and month picker for Monthly
      final picked = await showDatePicker(
        context: context,
        initialDate: state.selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        initialDatePickerMode: state.period == ReportPeriod.yearly ? DatePickerMode.year : DatePickerMode.day,
      );
      if (picked != null) notifier.setSelectedDate(picked);
    }
  }

  Widget _buildSummaryGrid(ReportSummary? summary) {
    final currency = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Bookings',
          value: summary?.bookingCount.toString() ?? '0',
          icon: Icons.event_available,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Total Revenue',
          value: currency.format(summary?.totalRevenue ?? 0),
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
        _StatCard(
          title: 'Advance Collected',
          value: currency.format(summary?.totalAdvance ?? 0),
          icon: Icons.account_balance_wallet,
          color: AppColors.gold,
        ),
        _StatCard(
          title: 'Balance Pending',
          value: currency.format(summary?.totalBalance ?? 0),
          icon: Icons.pending_actions,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildBreakdownChart(BuildContext context, ReportState state) {
    if (state.summary == null || state.summary!.breakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.period == ReportPeriod.yearly ? 'Monthly Revenue' : 'Daily Revenue',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: state.summary!.breakdown.fold(0.0, (max, item) => item.value > max ? item.value : max) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${NumberFormat.compact().format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= state.summary!.breakdown.length) return const SizedBox.shrink();
                        
                        // Show every 5th label for daily to avoid crowding
                        if (state.period == ReportPeriod.monthly && index % 5 != 0 && index != 0 && index != state.summary!.breakdown.length - 1) {
                            return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.summary!.breakdown[index].label,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: state.summary!.breakdown.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: AppColors.primary,
                        width: state.period == ReportPeriod.monthly ? 8 : 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallBreakdown(List<HallSummary> summaries) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hall-wise Performance',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        ...summaries.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(s.hallName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${s.bookingCount} Bookings'),
                trailing: Text(
                  '₹${NumberFormat.compact().format(s.revenue)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPendingBalances(BuildContext context, List<Booking> bookings) {
    if (bookings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Balances',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        ...bookings.map((b) {
          final balance = b.totalAmount - b.advancePaid;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => context.push('/booking-details/${b.id}'),
              title: Text('${b.groomName} & ${b.brideName}'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(b.eventDate)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${NumberFormat.compact().format(balance)}',
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                  const Text('Due', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _exportReport(BuildContext context, ReportState state) async {
    final pdf = pw.Document();
    final dateStr = _formatSelectedDate(state);
    final currency = NumberFormat.currency(symbol: 'Rs. ', locale: 'en_IN', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Financial Report - $dateStr', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildPdfStat('Bookings', state.summary?.bookingCount.toString() ?? '0'),
              _buildPdfStat('Revenue', currency.format(state.summary?.totalRevenue ?? 0)),
              _buildPdfStat('Advance', currency.format(state.summary?.totalAdvance ?? 0)),
              _buildPdfStat('Balance', currency.format(state.summary?.totalBalance ?? 0)),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text('Hall-wise Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headers: ['Hall Name', 'Bookings', 'Revenue'],
            data: state.hallSummaries.map((s) => [s.hallName, s.bookingCount.toString(), currency.format(s.revenue)]).toList(),
          ),
          pw.SizedBox(height: 30),
          pw.Text('Pending Balances', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headers: ['Party Names', 'Date', 'Total', 'Paid', 'Due'],
            data: state.balanceDueBookings.map((b) => [
              '${b.groomName} & ${b.brideName}',
              DateFormat('dd/MM/yy').format(b.eventDate),
              currency.format(b.totalAmount),
              currency.format(b.advancePaid),
              currency.format(b.totalAmount - b.advancePaid),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Report_$dateStr.pdf');
  }

  pw.Widget _buildPdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                ),
              ),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
