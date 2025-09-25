import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Fetch all reports from backend
  static Future<List<Map<String, dynamic>>> fetchReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['reports']);
        }
      }
      
      print('Failed to fetch reports: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  // Update report status
  static Future<bool> updateReportStatus(String alertId, String status, {String? resolution}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reports/$alertId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'resolution': resolution ?? '',
          'resolvedBy': 'Security Dashboard',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      print('Failed to update report status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }

  // Get dashboard statistics
  static Future<Map<String, dynamic>?> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['stats'];
        }
      }
      
      print('Failed to fetch stats: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching stats: $e');
      return null;
    }
  }
}