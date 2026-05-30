import 'package:flutter/material.dart';
import '../../../../data/models/admin_dashboard_stats_model.dart';
import '../repository/admin_dashboard_repository.dart';

enum DashboardPeriod {
  week('week', 'Tuần'),
  month('month', 'Tháng'),
  year('year', 'Năm');

  final String value;
  final String label;

  const DashboardPeriod(this.value, this.label);
}

class AdminDashboardViewModel extends ChangeNotifier {
  final AdminDashboardDataSource _repository;

  AdminDashboardStatsModel? _stats;
  DashboardPeriod _period = DashboardPeriod.month;
  DateTime _referenceDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardViewModel({AdminDashboardDataSource? repository})
    : _repository = repository ?? AdminDashboardRepository();

  AdminDashboardStatsModel? get stats => _stats;
  DashboardPeriod get period => _period;
  DateTime get referenceDate => _referenceDate;
  int get selectedMonth => _referenceDate.month;
  int get selectedYear => _referenceDate.year;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _repository.getStats(_period.value, _referenceDate);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePeriod(DashboardPeriod period) async {
    if (_period == period) return;

    _period = period;
    await loadStats();
  }

  Future<void> changeReferenceDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_referenceDate.year == normalizedDate.year &&
        _referenceDate.month == normalizedDate.month &&
        _referenceDate.day == normalizedDate.day) {
      return;
    }

    _referenceDate = normalizedDate;
    await loadStats();
  }

  Future<void> changeMonth(int month) async {
    if (_referenceDate.month == month) return;

    _referenceDate = DateTime(_referenceDate.year, month);
    await loadStats();
  }

  Future<void> changeYear(int year) async {
    if (_referenceDate.year == year) return;

    _referenceDate = DateTime(year, _referenceDate.month);
    await loadStats();
  }
}
