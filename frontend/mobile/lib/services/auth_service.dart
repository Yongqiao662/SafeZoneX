import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final BackendApiService _apiService = BackendApiService();
  Map<String, dynamic>? _currentUser;
  String? _authToken;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null && _currentUser != null;

  /// Initialize auth service and check for existing session
  Future<bool> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('current_user');

    if (token != null && userJson != null) {
      _authToken = token;
      _currentUser = json.decode(userJson);
      return true;
    }
    return false;
  }

  /// Google Sign-In Authentication
  Future<Map<String, dynamic>> signInWithGoogle(String idToken, String accessToken) async {
    try {
      final result = await _apiService.authenticateWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );

      if (result['success']) {
        await _saveAuthData(result['token'], result['user']);
        return {
          'success': true,
          'user': result['user'],
          'message': 'Google sign-in successful'
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Google sign-in failed: $e'
      };
    }
  }

  /// Email/Password Login
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      final result = await _apiService.loginWithEmail(
        email: email,
        password: password,
      );

      if (result['success']) {
        await _saveAuthData(result['token'], result['user']);
        return {
          'success': true,
          'user': result['user'],
          'message': 'Login successful'
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e'
      };
    }
  }

  /// Create new account
  Future<Map<String, dynamic>> createAccount({
    required String email,
    String? password,
    Map<String, dynamic>? googleData,
  }) async {
    try {
      return await _apiService.createUserAccount(
        email: email,
        password: password,
        googleData: googleData,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Account creation failed: $e'
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
    
    _authToken = null;
    _currentUser = null;
  }

  /// Save authentication data locally
  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('current_user', json.encode(user));
    
    _authToken = token;
    _currentUser = user;
  }

  /// Get user profile for reports (compatible with existing code)
  Map<String, dynamic>? getUserProfile() {
    if (_currentUser == null) return null;
    
    return {
      'userId': _currentUser!['_id'] ?? _currentUser!['id'],
      'userName': _currentUser!['name'] ?? _currentUser!['displayName'],
      'userPhone': _currentUser!['phone'] ?? '',
      'email': _currentUser!['email'],
    };
  }
}