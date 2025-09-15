import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BackendApiService {
  // AI-Powered SafeZoneX Backend URL
  static const String _baseUrl = 'http://localhost:8080';
  static const String _mobileUrl = 'http://10.0.2.2:8080'; // For Android emulator
  
  // Auto-detect the correct URL based on platform
  String get baseUrl {
    if (Platform.isAndroid) {
      return _mobileUrl;
    }
    return _baseUrl;
  }

  // Headers for all requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Check if the AI server is running
  Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'AI server is operational'
        };
      }
      return {'success': false, 'message': 'Server not responding'};
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  /// Submit a security report for AI analysis
  Future<Map<String, dynamic>> submitSecurityReport({
    required String text,
    required Map<String, double> location,
    Map<String, dynamic>? userProfile,
    List<File>? images,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create multipart request for file uploads
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/ai/analyze-report'),
      );

      // Add text data
      request.fields['text'] = text;
      request.fields['location'] = json.encode(location);
      request.fields['userProfile'] = json.encode(userProfile ?? {});
      request.fields['metadata'] = json.encode(metadata ?? {
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'mobile_app',
        'version': '2.0.0'
      });

      // Add image files if provided
      if (images != null) {
        for (int i = 0; i < images.length && i < 5; i++) {
          request.files.add(await http.MultipartFile.fromPath(
            'images',
            images[i].path,
          ));
        }
      }

      print('🚀 Submitting report to AI analysis...');
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Increased timeout for ML processing
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ AI analysis completed: ${result['analysis']['verification']['isAuthentic']}');
        return {
          'success': true,
          'analysis': result['analysis'],
          'message': 'AI analysis completed successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'AI analysis failed: ${response.body}'
        };
      }
    } catch (e) {
      print('❌ Report submission error: $e');
      return {
        'success': false,
        'message': 'Failed to submit report: $e'
      };
    }
  }

  /// Get safety predictions for a location
  Future<Map<String, dynamic>> getSafetyPredictions({
    required Map<String, double> location,
    int timeRange = 7,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/predict-safety'),
        headers: _headers,
        body: json.encode({
          'location': location,
          'timeRange': timeRange,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'predictions': result['predictions'],
          'message': 'Safety predictions retrieved'
        };
      }
      return {'success': false, 'message': 'Failed to get predictions'};
    } catch (e) {
      return {'success': false, 'message': 'Prediction request failed: $e'};
    }
  }

  /// Get active threats from the AI system
  Future<Map<String, dynamic>> getActiveThreats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/threats/active'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'threats': result['activeThreats'],
          'statistics': result['statistics'],
          'message': 'Active threats retrieved'
        };
      }
      return {'success': false, 'message': 'Failed to get threats'};
    } catch (e) {
      return {'success': false, 'message': 'Threats request failed: $e'};
    }
  }

  /// Get ML training status
  Future<Map<String, dynamic>> getMLStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ml/status'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'status': result,
          'message': 'ML status retrieved'
        };
      }
      return {'success': false, 'message': 'Failed to get ML status'};
    } catch (e) {
      return {'success': false, 'message': 'ML status request failed: $e'};
    }
  }

  /// Trigger ML model training (admin function)
  Future<Map<String, dynamic>> trainMLModels() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ml/train'),
        headers: _headers,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'training': result['training'],
          'message': 'ML training completed'
        };
      }
      return {'success': false, 'message': 'Failed to train models'};
    } catch (e) {
      return {'success': false, 'message': 'ML training failed: $e'};
    }
  }

  /// Test ML prediction with sample data
  Future<Map<String, dynamic>> testMLPrediction({
    required Map<String, dynamic> reportData,
    required String predictionType, // 'authenticity' or 'threat'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ml/predict'),
        headers: _headers,
        body: json.encode({
          'reportData': reportData,
          'predictionType': predictionType,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'prediction': result['prediction'],
          'modelInfo': result['modelInfo'],
          'message': 'ML prediction completed'
        };
      }
      return {'success': false, 'message': 'Failed to get prediction'};
    } catch (e) {
      return {'success': false, 'message': 'ML prediction failed: $e'};
    }
  }

  /// Get model performance metrics
  Future<Map<String, dynamic>> getModelMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ml/metrics'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'metrics': result['metrics'],
          'message': 'Model metrics retrieved'
        };
      }
      return {'success': false, 'message': 'Failed to get metrics'};
    } catch (e) {
      return {'success': false, 'message': 'Metrics request failed: $e'};
    }
  }
}
