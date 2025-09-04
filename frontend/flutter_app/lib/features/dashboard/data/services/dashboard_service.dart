// lib/features/dashboard/data/services/dashboard_service.dart

import 'dart:convert';
import '../models/dashboard_data.dart';
import '../../../../core/services/api_service.dart';

class DashboardService {
  final ApiService _apiService;

  DashboardService(this._apiService);

  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _apiService.get('/games/dashboard_data/');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        try {
          final dashboardData = DashboardData.fromJson(data);
          return dashboardData;
        } catch (parseError) {
          throw Exception('Failed to parse dashboard data: $parseError');
        }
      } else {
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }
}
