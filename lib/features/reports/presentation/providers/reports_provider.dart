import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/reports_service.dart';
import '../../../../features/dashboard/domain/models/booking.dart';

final reportsServiceProvider = Provider((ref) => ReportsService());

enum ReportPeriod { daily, monthly, yearly }

class ReportState {
  final ReportPeriod period;
  final DateTime selectedDate;
  final bool isLoading;
  final ReportSummary? summary;
  final List<HallSummary> hallSummaries;
  final List<Booking> balanceDueBookings;
  final String? error;

  ReportState({
    required this.period,
    required this.selectedDate,
    this.isLoading = false,
    this.summary,
    this.hallSummaries = const [],
    this.balanceDueBookings = const [],
    this.error,
  });

  ReportState copyWith({
    ReportPeriod? period,
    DateTime? selectedDate,
    bool? isLoading,
    ReportSummary? summary,
    List<HallSummary>? hallSummaries,
    List<Booking>? balanceDueBookings,
    String? error,
  }) {
    return ReportState(
      period: period ?? this.period,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      hallSummaries: hallSummaries ?? this.hallSummaries,
      balanceDueBookings: balanceDueBookings ?? this.balanceDueBookings,
      error: error,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportsService _service;

  ReportNotifier(this._service)
      : super(ReportState(period: ReportPeriod.daily, selectedDate: DateTime.now())) {
    loadReport();
  }

  void setPeriod(ReportPeriod period) {
    state = state.copyWith(period: period);
    loadReport();
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      ReportSummary summary;
      DateTimeRange range;

      switch (state.period) {
        case ReportPeriod.daily:
          summary = await _service.getDailySummary(state.selectedDate);
          range = DateTimeRange(
            start: DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day),
            end: DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day, 23, 59, 59),
          );
          break;
        case ReportPeriod.monthly:
          summary = await _service.getMonthlySummary(state.selectedDate.year, state.selectedDate.month);
          range = DateTimeRange(
            start: DateTime(state.selectedDate.year, state.selectedDate.month, 1),
            end: DateTime(state.selectedDate.year, state.selectedDate.month + 1, 0, 23, 59, 59),
          );
          break;
        case ReportPeriod.yearly:
          summary = await _service.getYearlySummary(state.selectedDate.year);
          range = DateTimeRange(
            start: DateTime(state.selectedDate.year, 1, 1),
            end: DateTime(state.selectedDate.year, 12, 31, 23, 59, 59),
          );
          break;
      }

      final hallSummaries = await _service.getHallWiseSummary(range);
      final balanceDue = await _service.getBalanceDueList(range);

      state = state.copyWith(
        isLoading: false,
        summary: summary,
        hallSummaries: hallSummaries,
        balanceDueBookings: balanceDue,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final reportsProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(ref.watch(reportsServiceProvider));
});
