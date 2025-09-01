// lib/features/dashboard/data/services/dashboard_service.dart

import 'dart:convert';
import '../models/dashboard_data.dart';
import '../../../../core/services/api_service.dart';

class DashboardService {
  final ApiService _apiService;

  DashboardService(this._apiService);

  Future<DashboardData> getDashboardData() async {
    try {
      print('DashboardService: Making API request to /games/dashboard_data/');
      final response = await _apiService.get('/games/dashboard_data/');
      print('DashboardService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('DashboardService: Parsing response body');
        final Map<String, dynamic> data = json.decode(response.body);
        print('DashboardService: Response data keys: ${data.keys.toList()}');
        try {
          final dashboardData = DashboardData.fromJson(data);
          print('DashboardService: Successfully parsed dashboard data');
          return dashboardData;
        } catch (parseError) {
          print('DashboardService: Parse error: $parseError');
          throw Exception('Failed to parse dashboard data: $parseError');
        }
      } else {
        print('DashboardService: HTTP error: ${response.statusCode}');
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      print('DashboardService: Exception: $e');
      throw Exception('Failed to load dashboard data: $e');
    }
  }
}
