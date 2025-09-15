import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'location_tracking_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocket? _webSocket;
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _webSocket != null;

  Future<void> connect() async {
    try {
      // Auto-detect the correct WebSocket URL based on platform
      String serverUrl;
      
      if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to reach localhost
        serverUrl = 'ws://10.0.2.2:8080';
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost
        serverUrl = 'ws://localhost:8080';
      } else {
        // Physical devices need your computer's IP address
        // Replace 192.168.1.xxx with your actual IP from ipconfig
        serverUrl = 'ws://192.168.1.100:8080'; // UPDATE THIS IP!
      }
      
      print('🔌 Attempting WebSocket connection to $serverUrl');
      _webSocket = await WebSocket.connect(serverUrl);
      
      print('✅ AI-powered WebSocket connected to SafeZoneX server');
      
      // Register as mobile client for AI notifications
      sendMessage({
        'type': 'register',
        'clientType': 'mobile',
        'capabilities': ['threat_alerts', 'ai_analysis', 'real_time_updates'],
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _webSocket!.listen((message) {
        try {
          final data = json.decode(message);
          print('📨 Received AI notification: ${data['type']}');
          _messageController.add(data);
        } catch (e) {
          print('❌ Error parsing WebSocket message: $e');
        }
      }, onError: (error) {
        print('❌ WebSocket error: $error');
        _reconnect();
      }, onDone: () {
        print('WebSocket connection closed');
        _reconnect();
      });
      
    } catch (e) {
      print('Failed to connect: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!isConnected) {
        connect();
      }
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (isConnected) {
      _webSocket!.add(json.encode(message));
    } else {
      print('WebSocket not connected, cannot send message');
    }
  }

  // Enhanced SOS alert with real-time location
  Future<void> sendSOSAlertWithRealLocation({
    required String userId,
    required String userName,
    required String userPhone,
    String alertType = 'Emergency SOS',
    String? additionalInfo,
    String? emergencyContact,
  }) async {
    final locationService = LocationTrackingService();
    
    // Ensure we have current location
    await locationService.getCurrentLocation();
    final locationData = locationService.getEmergencyLocationData();
    
    sendSOSAlert(
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      latitude: locationData['latitude'],
      longitude: locationData['longitude'],
      address: locationData['address'],
      alertType: alertType,
      additionalInfo: additionalInfo ?? 
        'SOS with live GPS - Accuracy: ${locationData['accuracy']?.toStringAsFixed(1) ?? 'Unknown'}m',
    );
  }

  // Send live location updates during tracking
  void sendLocationUpdate({
    required String userId,
    required double latitude,
    required double longitude,
    required String address,
    String? status,
    Map<String, dynamic>? additionalData,
  }) {
    sendMessage({
      'type': 'location_update',
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status ?? 'tracking',
      'timestamp': DateTime.now().toIso8601String(),
      'additionalData': additionalData ?? {},
    });
  }

  void sendSOSAlert({
    required String userId,
    required String userName,
    required String userPhone,
    required double latitude,
    required double longitude,
    required String address,
    String alertType = 'Emergency',
    String? additionalInfo,
  }) {
    final alertData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': DateTime.now().toIso8601String(),
      'alertType': alertType,
      'status': 'active',
      'additionalInfo': additionalInfo,
    };

    sendMessage({
      'type': 'sos_alert',
      'payload': alertData,
    });

    print('🚨 SOS Alert sent: $alertData');
  }

  void sendWalkingPartnerRequest({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String destination,
  }) {
    sendMessage({
      'type': 'walking_partner_request',
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'destination': destination,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendChatMessage({
    required String userId,
    required String userName,
    required String message,
    String type = 'support',
  }) {
    sendMessage({
      'type': 'chat_message',
      'userId': userId,
      'userName': userName,
      'message': message,
      'chatType': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    _webSocket?.close();
    _webSocket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
