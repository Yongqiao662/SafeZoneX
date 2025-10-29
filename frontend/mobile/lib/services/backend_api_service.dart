import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BackendApiService {
  // Use centralized ApiService baseUrl (env-driven) so mobile can target Netlify or local
  String get baseUrl => ApiService.baseUrl;

  // Headers for all requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Submit a security report for AI analysis
  Future<Map<String, dynamic>> submitSecurityReport({
    required String text,
    required Map<String, double> location,
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Build the JSON body
      final latitude = location['latitude'] ?? location['lat'] ?? 3.12194;
      final longitude = location['longitude'] ?? location['lng'] ?? 101.6569867;
      final address = metadata?['locationName'] ?? 'Test Location';
      
      // Get evidence images from metadata
      final evidenceImages = metadata?['evidenceImages'] ?? [];
      
      print('📤 BackendApiService: Preparing report submission');
      print('   Images to send: ${evidenceImages.length}');
      
      final body = {
        'description': text.isNotEmpty ? text : 'Test report description',
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'campus': 'University Malaya',
        },
        'alertType': metadata?['activityType'] ?? 'emergency',
        'priority': metadata?['priority'] ?? 'high',
        'userId': userProfile?['userId'] ?? 'test_user_123',
        'userName': userProfile?['userName'] ?? 'Test User',
        'userPhone': userProfile?['userPhone'] ?? '+60123456789',
        'evidenceImages': evidenceImages, // Include images
      };

      print('📤 Sending request to: ${baseUrl}/api/report');
      
      final response = await http.post(
        Uri.parse('${baseUrl}/api/report'),
        headers: _headers,
        body: json.encode(body),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Report submitted successfully');
        return result;
      } else {
        print('❌ Server error: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Failed to submit report: ${response.reasonPhrase}'};
      }
    } catch (e) {
      print('❌ Exception in submitSecurityReport: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Check if the AI server is running
  Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/api/status'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Server is running'};
      }
      return {'success': false, 'message': 'Server is down'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get ML model status
  Future<Map<String, dynamic>> getMLStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/api/ml/status'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'status': result['status'],
          'message': 'ML status retrieved'
        };
      }
      return {'success': false, 'message': 'Failed to get ML status'};
    } catch (e) {
      return {'success': false, 'message': 'ML status request failed: $e'};
    }
  }

  /// Train ML models
  Future<Map<String, dynamic>> trainMLModels() async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/api/ml/train'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
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

  /// Get active threats
  Future<Map<String, dynamic>> getActiveThreats() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/api/threats/active'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'threats': result['threats'],
          'message': 'Active threats retrieved'
        };
      }
      return {'success': false, 'message': 'Failed to get active threats'};
    } catch (e) {
      return {'success': false, 'message': 'Threats request failed: $e'};
    }
  }

  /// Authenticate user with Google token
  Future<Map<String, dynamic>> authenticateWithGoogle({
    required String idToken,
    required String accessToken,
  }) async {
    final payload = {
      'idToken': idToken,
      'accessToken': accessToken,
      'authProvider': 'google',
    };

    try {
      print('🔐 Authenticating with Google...');
      print('🔗 Backend URL: ${baseUrl}/api/auth/google');
      
      final response = await http.post(
        Uri.parse('${baseUrl}/api/auth/google'),
        headers: _headers,
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      print('� Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          return {
            'success': true,
            'user': result['user'],
            'token': result['token'],
            'message': 'Google authentication successful'
          };
        } catch (jsonError) {
          print('❌ JSON decode error: $jsonError');
          print('📄 Response body: ${response.body}');
          return {
            'success': false,
            'message': 'Server returned invalid response format'
          };
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        print('📄 Error response: ${response.body}');
        
        // Try to parse error response, but handle HTML responses gracefully
        try {
          final error = json.decode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Google authentication failed'
          };
        } catch (_) {
          // Server returned HTML or non-JSON (likely 404/500 page)
          return {
            'success': false,
            'message': 'Authentication service unavailable (${response.statusCode})'
          };
        }
      }
    } catch (e) {
      print('❌ Authentication request failed: $e');
      return {
        'success': false,
        'message': 'Network error: Unable to connect to authentication service'
      };
    }
  }

  /// Create new user account with email verification
  Future<Map<String, dynamic>> createUserAccount({
    required String email,
    String? password,
    Map<String, dynamic>? googleData,
  }) async {
    final payload = {
      'email': email,
      'password': password,
      'authProvider': googleData != null ? 'google' : 'email',
      'googleData': googleData,
      'university': 'University Malaya', // Set default university
    };

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/api/auth/register'),
        headers: _headers,
        body: json.encode(payload),
      );

      print('👤 Creating user account...');
      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'user': result['user'],
          'requiresVerification': result['requiresVerification'] ?? false,
          'message': 'Account created successfully'
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Account creation failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Account creation error: $e'
      };
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final payload = {
      'email': email,
      'password': password,
    };

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/api/auth/login'),
        headers: _headers,
        body: json.encode(payload),
      );

      print('🔑 Logging in with email...');
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'user': result['user'],
          'token': result['token'],
          'message': 'Login successful'
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error: $e'
      };
    }
  }
}