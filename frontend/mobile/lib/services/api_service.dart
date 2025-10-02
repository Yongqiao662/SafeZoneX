import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend URL - change this to your actual backend URL
  static const String baseUrl = 'http://10.0.2.2:8080'; // For Android emulator
  // Use 'http://localhost:8080' for iOS simulator
  // Use 'http://YOUR_IP:8080' for physical devices

  // ==================== USER MANAGEMENT API ====================

  /// Register a new user
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String name,
    String? phone,
    String? studentId,
    String? profilePicture,
  }) async {
    try {
      print('🔵 Registering user: $email');
      print('🔵 Backend URL: $baseUrl/api/users/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.toLowerCase(),
          'name': name,
          'phone': phone ?? '',
          'studentId': studentId ?? '',
          'profilePicture': profilePicture ?? '',
        }),
      ).timeout(Duration(seconds: 10));

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Registration failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering user: $e');
      rethrow;
    }
  }

  // ==================== FRIENDS API ====================

  /// Fetch all friends for a user
  static Future<Map<String, dynamic>> getFriends(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/friends/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch friends: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching friends: $e');
      rethrow;
    }
  }

  /// Add a new friend by email
  static Future<Map<String, dynamic>> addFriend({
    required String userId,
    required String friendEmail,
    required String userName,
    required String userEmail,
    String profileColor = 'blue',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/friends/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'friendEmail': friendEmail,
          'userName': userName,
          'userEmail': userEmail,
          'profileColor': profileColor,
        }),
      ).timeout(Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      print('❌ Error adding friend: $e');
      rethrow;
    }
  }

  /// Search for users by email
  static Future<Map<String, dynamic>> searchUsers(String email, String currentUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/search?email=$email&currentUserId=$currentUserId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      print('❌ Error searching users: $e');
      rethrow;
    }
  }

  // ==================== CHAT/MESSAGING API ====================

  /// Get chat messages between current user and a friend
  static Future<Map<String, dynamic>> getMessages(
    String userId,
    String friendId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/$userId/$friendId?limit=$limit&offset=$offset'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch messages');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      rethrow;
    }
  }

  /// Send a message to a friend
  static Future<Map<String, dynamic>> sendMessage({
    required String senderId,
    required String recipientId,
    required String message,
    required String senderName,
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': senderId,
          'recipientId': recipientId,
          'message': message,
          'senderName': senderName,
          'messageType': messageType,
        }),
      ).timeout(Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  static Future<Map<String, dynamic>> markMessagesAsRead(
    String userId,
    String friendId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/messages/read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'friendId': friendId,
        }),
      ).timeout(Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      rethrow;
    }
  }

  // ==================== VERIFICATION CODE API ====================

  /// Send verification code to email
  static Future<Map<String, dynamic>> sendVerificationCode(
    String email, {
    String purpose = 'email_verification',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/verification/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'purpose': purpose,
        }),
      ).timeout(Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      print('❌ Error sending verification code: $e');
      rethrow;
    }
  }

  /// Verify the code entered by user
  static Future<Map<String, dynamic>> verifyCode(
    String email,
    String code, {
    String purpose = 'email_verification',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/verification/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'purpose': purpose,
        }),
      ).timeout(Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      print('❌ Error verifying code: $e');
      rethrow;
    }
  }

  // ==================== USER PREFERENCES ====================

  /// Save user credentials after registration/login
  static Future<void> saveUserCredentials({
    required String userId,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_email', email.toLowerCase());
    await prefs.setString('user_name', name);
    await prefs.setBool('is_logged_in', true);
    print('✅ User credentials saved: $userId ($email)');
  }

  /// Get current user ID from SharedPreferences
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Get current user name from SharedPreferences
  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  /// Get current user email from SharedPreferences
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// Logout user (clear credentials)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    print('✅ User logged out successfully');
  }

  /// Check if user exists in database by email
  static Future<Map<String, dynamic>> checkUserExists(String email) async {
    try {
      print('🔍 Checking if user exists: $email');
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/check?email=${Uri.encodeComponent(email)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'exists': false};
      }
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return {'exists': false};
    }
  }
}
