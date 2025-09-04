import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import '../models/sos_alert.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  html.WebSocket? _webSocket;
  final StreamController<SOSAlert> _alertController = StreamController<SOSAlert>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  
  Stream<SOSAlert> get alertStream => _alertController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  
  bool get isConnected => _webSocket?.readyState == html.WebSocket.OPEN;

  Future<void> connect() async {
    try {
      // Connect to our local WebSocket server (web dashboard runs on same machine)
      _webSocket = html.WebSocket('ws://localhost:8080');
      
      _webSocket!.onOpen.listen((event) {
        print('✅ Web Dashboard WebSocket connected');
        _connectionController.add('connected');
        
        // Register as web client
        sendMessage({
          'register': true,
          'type': 'web',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      
      _webSocket!.onMessage.listen((event) {
        try {
          final data = json.decode(event.data);
          if (data['type'] == 'sos_alert') {
            final alert = SOSAlert.fromJson(data['payload']);
            _alertController.add(alert);
            _showBrowserNotification(alert);
          }
        } catch (e) {
          print('Error parsing message: $e');
        }
      });
      
      _webSocket!.onError.listen((event) {
        print('WebSocket error: $event');
        _connectionController.add('error');
      });
      
      _webSocket!.onClose.listen((event) {
        print('WebSocket closed');
        _connectionController.add('disconnected');
        _reconnect();
      });
      
    } catch (e) {
      print('Failed to connect: $e');
      _connectionController.add('error');
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
      _webSocket!.send(json.encode(message));
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

  void _showBrowserNotification(SOSAlert alert) {
    if (html.Notification.supported) {
      html.Notification.requestPermission().then((permission) {
        if (permission == 'granted') {
          final notification = html.Notification(
            'SafeZoneX - Emergency Alert!',
            body: '${alert.userName} needs help at ${alert.address}',
            icon: '/icons/Icon-192.png',
            tag: alert.id,
          );
          
          notification.onClick.listen((event) {
            // html.window.focus(); // Removed problematic line
            notification.close();
          });
          
          // Auto close after 10 seconds
          Timer(const Duration(seconds: 10), () {
            notification.close();
          });
        }
      });
    }
  }

  void dispose() {
    _webSocket?.close();
    _alertController.close();
    _connectionController.close();
  }
}
