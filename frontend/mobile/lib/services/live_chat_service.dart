import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class LiveChatService {
  static final LiveChatService _instance = LiveChatService._internal();
  factory LiveChatService() => _instance;
  LiveChatService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  List<Function(dynamic)> _messageListeners = [];
  List<Function(bool)> _connectionListeners = [];
  List<Function(dynamic)> _typingListeners = [];
  String? _userId;
  String? _userName;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  void connect() {
    // If socket exists and is connected, just return
    if (_socket != null && _socket!.connected) {
      print('✅ Live chat already connected');
      _notifyConnectionListeners(true);
      return;
    }

    // If socket exists but disconnected, try to reconnect
    if (_socket != null && !_socket!.connected) {
      print('🔄 Reconnecting existing socket...');
      _socket!.connect();
      return;
    }

    // Create new socket connection
    final backendUrl = ApiService.baseUrl;
    print('🔌 Creating new live chat connection at: $backendUrl');

    _socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 10,
      'timeout': 20000,
      'forceNew': false,
    });

    _socket!.on('connect', (_) {
      print('✅ Connected to live chat service at $backendUrl');
      _isConnected = true;
      _notifyConnectionListeners(true);

      // Rejoin if we have user data
      if (_userId != null && _userName != null) {
        _socket!.emit('user_join_support', {
          'userId': _userId,
          'userName': _userName,
        });
        print('📤 Rejoined support chat as $_userName (ID: $_userId)');
      }
    });

    _socket!.on('disconnect', (_) {
      print('❌ Disconnected from live chat service');
      _isConnected = false;
      _notifyConnectionListeners(false);
    });

    _socket!.on('connect_error', (error) {
      print('❌ Connection error: $error');
      print('💡 Make sure the backend server is running on $backendUrl');
      _isConnected = false;
      _notifyConnectionListeners(false);
    });

    _socket!.on('connect_timeout', (_) {
      print('❌ Connection timeout - Backend may not be running');
      print('💡 Check if server is running with: cd backend && npm start');
      _isConnected = false;
      _notifyConnectionListeners(false);
    });

    _socket!.on('support_message', (data) {
      print('📨 Received message: $data');
      _notifyMessageListeners(data);
    });

    _socket!.on('security_typing', (data) {
      print('⌨️ Security typing');
      _notifyTypingListeners(data);
    });
  }

  void disconnect() {
    print('🔌 Disconnect called - keeping socket alive for reconnection');
    // Don't actually disconnect or dispose - keep the socket alive
    // Just notify that we're "disconnecting" from the UI perspective
    // The socket will auto-reconnect if needed
  }

  void joinSupport(String userId, String userName) {
    _userId = userId;
    _userName = userName;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('user_join_support', {
        'userId': userId,
        'userName': userName,
      });
      print('👤 Joined support as $userName (ID: $userId)');
    }
  }

  void sendMessage(String message) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('user_support_message', {
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': _userId,
        'userName': _userName,
      });
    }
  }

  void sendTypingIndicator() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('user_typing', {'userId': _userId});
    }
  }

  void addMessageListener(Function(dynamic) listener) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(Function(dynamic) listener) {
    _messageListeners.remove(listener);
  }

  void addConnectionListener(Function(bool) listener) {
    _connectionListeners.add(listener);
  }

  void removeConnectionListener(Function(bool) listener) {
    _connectionListeners.remove(listener);
  }

  void addTypingListener(Function(dynamic) listener) {
    _typingListeners.add(listener);
  }

  void removeTypingListener(Function(dynamic) listener) {
    _typingListeners.remove(listener);
  }

  void _notifyMessageListeners(dynamic data) {
    for (var listener in _messageListeners) {
      listener(data);
    }
  }

  void _notifyConnectionListeners(bool connected) {
    for (var listener in _connectionListeners) {
      listener(connected);
    }
  }

  void _notifyTypingListeners(dynamic data) {
    for (var listener in _typingListeners) {
      listener(data);
    }
  }

  void clearListeners() {
    _messageListeners.clear();
    _connectionListeners.clear();
    _typingListeners.clear();
  }
}
