import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'location_tracking_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  String? _jwtToken;
  final StreamController<Map<String, dynamic>> _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _socket != null && _socket!.connected;

  /// Connect to Socket.IO server with JWT token for authentication
  void connect(String token) {
  _jwtToken = token;
    String serverUrl;
    if (Platform.isAndroid) {
      serverUrl = 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      serverUrl = 'http://localhost:8080';
    } else {
      serverUrl = 'http://192.168.1.100:8080'; // UPDATE THIS IP!
    }
    print('🔌 Attempting Socket.IO connection to $serverUrl');
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token,
      },
    });
    _socket!.on('connect', (_) {
      print('✅ Socket.IO connected to SafeZoneX server');
      sendMessage({
        'type': 'register',
        'clientType': 'mobile',
        'capabilities': ['threat_alerts', 'ai_analysis', 'real_time_updates'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _socket!.on('report_update', (data) {
      print('📨 Received report_update: $data');
      _messageController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('disconnect', (_) {
      print('Socket.IO disconnected');
      _reconnect();
    });
    _socket!.on('error', (error) {
      print('❌ Socket.IO error: $error');
      _reconnect();
    });
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!isConnected && _jwtToken != null) {
        connect(_jwtToken!);
      }
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (isConnected) {
      _socket!.emit('message', message);
    } else {
      print('Socket.IO not connected, cannot send message');
    }
  }

  // Enhanced SOS alert with real-time location - FIXED VERSION
  Future<void> sendSOSAlertWithRealLocation({
    required String userId,
    required String userName,
    required String userPhone,
    String alertType = 'Emergency SOS',
    String? additionalInfo,
    String? emergencyContact,
  }) async {
    final locationService = LocationTrackingService();
    
    print('📍 Getting GPS location for emergency report...');
    
    // Force initialize the location service first
    await locationService.initialize();
    
    // Get fresh GPS location
    await locationService.getCurrentLocation();
    
    final locationData = locationService.getEmergencyLocationData();
    
    // Check if GPS coordinates are valid (not 0.0 and not null)
    double latitude = locationData['latitude'] ?? 0.0;
    double longitude = locationData['longitude'] ?? 0.0;
    
    // If GPS failed or returned invalid coordinates, use University Malaya as fallback
    if (latitude == 0.0 || longitude == 0.0) {
      print('⚠️ GPS failed, using University Malaya coordinates as fallback');
      latitude = 3.1319;   // University Malaya latitude
      longitude = 101.6841; // University Malaya longitude
    } else {
      print('✅ Using real GPS coordinates: $latitude, $longitude');
    }
    
    // Use address from GPS if available, otherwise create fallback address
    String address = locationData['address'] ?? 'Current Location (GPS)';
    if (latitude == 3.1319 && longitude == 101.6841) {
      address = 'University Malaya Campus (GPS Fallback)';
    }
    
    sendSOSAlert(
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      latitude: latitude,
      longitude: longitude,
      address: address,
      alertType: alertType,
      additionalInfo: additionalInfo ?? 
        'Emergency alert with GPS location - Accuracy: ${locationData['accuracy']?.toStringAsFixed(1) ?? 'Unknown'}m',
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

    print('🚨 SOS Alert sent with coordinates: $latitude, $longitude');
    print('📍 Address: $address');
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
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}