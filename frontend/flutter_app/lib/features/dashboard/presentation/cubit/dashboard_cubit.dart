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
    emit(DashboardLoading());
    
    try {
      final dashboardData = await _dashboardService.getDashboardData();
      emit(DashboardLoaded(dashboardData));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void refresh() {
    loadDashboardData();
  }
}
