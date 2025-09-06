// lib/features/dashboard/presentation/cubit/dashboard_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/services/dashboard_service.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardService _dashboardService;
  DateTime? _lastFetchTime;
  static const Duration _minRefreshInterval = Duration(minutes: 2);

  DashboardCubit(this._dashboardService) : super(DashboardInitial());

  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    // Always fetch fresh data when forceRefresh is true, otherwise use smart refresh
    if (!forceRefresh && _shouldSkipFetch()) {
      return;
    }

    emit(DashboardLoading());
    
    try {
      // Always use forceRefresh=true to bypass backend cache when explicitly requested
      final dashboardData = await _dashboardService.getDashboardData(forceRefresh: forceRefresh);
      _lastFetchTime = DateTime.now();
      emit(DashboardLoaded(dashboardData));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void refresh() {
    loadDashboardData(forceRefresh: true);
  }

  bool _shouldSkipFetch() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _minRefreshInterval;
  }
}
