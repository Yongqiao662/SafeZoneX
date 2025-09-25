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
        // 'evidenceImages': [], // Images omitted for now
      };

      final response = await http.post(
        Uri.parse('${baseUrl}/api/report'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to submit report: ${response.reasonPhrase}'};
      }
    } catch (e) {
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
    final response = await http.post(
      Uri.parse('${baseUrl}/api/auth/google'),
      headers: _headers,
      body: json.encode(payload),
    );

    print('🔐 Authenticating with Google...');
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return {
        'success': true,
        'user': result['user'],
        'token': result['token'],
        'message': 'Google authentication successful'
      };
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Google authentication failed'
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Google authentication error: $e'
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
