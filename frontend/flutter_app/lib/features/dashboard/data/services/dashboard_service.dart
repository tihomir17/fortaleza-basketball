// lib/features/dashboard/data/services/dashboard_service.dart

import 'dart:convert';
import '../models/dashboard_data.dart';
import '../../../../core/services/api_service.dart';

class DashboardService {
  final ApiService _apiService;

  DashboardService(this._apiService);

  Future<DashboardData> getDashboardData({bool forceRefresh = false}) async {
    try {
      String url = '/games/dashboard_data/';
      
      // Add cache-busting parameter when force refresh is requested
      if (forceRefresh) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        url += '?force_refresh=$timestamp';
      }
      
      final response = await _apiService.get(url);
      
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
