import 'package:socket_io_client/socket_io_client.dart' as IO;

class BackendService {
  late IO.Socket socket;
  
  void connect() {
    socket = IO.io('http://10.0.2.2:8080', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    socket.connect();
    
    socket.on('connect', (_) {
      print('Connected to SafeZoneX backend');
    });
    
    socket.on('disconnect', (_) {
      print('Disconnected from backend');
    });
  }
  
  void sendSOSAlert({
    required String userId,
    required String userName,
    required String userPhone,
    required double latitude,
    required double longitude,
    required String address,
    String? additionalInfo,
  }) {
    socket.emit('sos_alert', {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'alertType': 'Emergency',
      'additionalInfo': additionalInfo,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}