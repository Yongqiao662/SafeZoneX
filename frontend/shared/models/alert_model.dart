class Alert {
  final String id;
  final String type;
  final DateTime timestamp;
  final String location;
  final String userId;
  final String userName;
  final String userPhone;
  final double latitude;
  final double longitude;
  final String status;
  final String? additionalInfo;
  final String? emergencyContact;

  Alert({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.location,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    this.additionalInfo,
    this.emergencyContact,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      userId: json['userId'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      status: json['status'] ?? 'active',
      additionalInfo: json['additionalInfo'],
      emergencyContact: json['emergencyContact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'additionalInfo': additionalInfo,
      'emergencyContact': emergencyContact,
    };
  }

  Alert copyWith({
    String? id,
    String? type,
    DateTime? timestamp,
    String? location,
    String? userId,
    String? userName,
    String? userPhone,
    double? latitude,
    double? longitude,
    String? status,
    String? additionalInfo,
    String? emergencyContact,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
