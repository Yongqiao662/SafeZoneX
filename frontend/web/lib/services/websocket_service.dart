import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/sos_alert.dart';

class WebSocketService {
  final StreamController<Map<String, dynamic>> _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final StreamController<SOSAlert> _alertController = StreamController<SOSAlert>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  
  Stream<SOSAlert> get alertStream => _alertController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    String socketUrl;
    if (kIsWeb) {
      socketUrl = 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      socketUrl = 'http://10.0.2.2:8080';
    } else {
      socketUrl = 'http://localhost:8080';
    }

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.on('connect', (_) {
      print('✅ Socket.IO connected');
      _connectionController.add('connected');
      sendMessage({
        'register': true,
        'type': 'web',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    _socket!.on('report_update', (data) {
      try {
        print('Received report_update: $data');
        // Parse all required fields for SOSAlert
        final alert = SOSAlert(
          id: data['alertId'] ?? 'unknown',
          userId: data['userId'] ?? 'mobile_user',
          userName: data['userName'] ?? 'Mobile Reporter',
          userPhone: '+60123456789',
          latitude: data['location']?['latitude'] ?? 3.1235,
          longitude: data['location']?['longitude'] ?? 101.6545,
          address: data['location']?['address'] ?? 'University Malaya',
          timestamp: DateTime.now(),
          alertType: data['alertType'] ?? 'Emergency',
          status: data['status'] ?? 'active',
          additionalInfo: data['description'] ?? 'Report from mobile app',
        );
        _alertController.add(alert);
        _messageController.add({
          'type': 'report_update',
          'alertId': data['alertId'],
          'status': data['status'],
          'aiAnalysis': data['aiAnalysis'],
        });
      } catch (e) {
        print('Error parsing report_update: $e');
      }
    });

    _socket!.on('error', (err) {
      print('Socket.IO error: $err');
      _connectionController.add('error');
    });

    _socket!.on('disconnect', (_) {
      print('Socket.IO disconnected');
      _connectionController.add('disconnected');
      _reconnect();
    });
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
  _socket!.emit('message', message);
    }
  }

  void acknowledgeAlert(String alertId) {
    sendMessage({
      'type': 'acknowledge_alert',
      'alertId': alertId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void resolveAlert(String alertId) {
    sendMessage({
      'type': 'resolve_alert', 
      'alertId': alertId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }


  void dispose() {
  _socket?.disconnect();
    _alertController.close();
    _connectionController.close();
  }
}
