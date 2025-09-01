// lib/features/dashboard/presentation/cubit/dashboard_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/services/dashboard_service.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardService _dashboardService;

  DashboardCubit(this._dashboardService) : super(DashboardInitial());

  Future<void> loadDashboardData() async {
    print('DashboardCubit: Starting to load dashboard data');
    emit(DashboardLoading());
    
    try {
      print('DashboardCubit: Calling dashboard service');
      final dashboardData = await _dashboardService.getDashboardData();
      print('DashboardCubit: Dashboard data loaded successfully: ${dashboardData.quickStats.totalGames} games');
      emit(DashboardLoaded(dashboardData));
    } catch (e) {
      print('DashboardCubit: Error loading dashboard data: $e');
      emit(DashboardError(e.toString()));
    }
  }

  void refresh() {
    loadDashboardData();
  }
}
