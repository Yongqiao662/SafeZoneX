class SOSAlert {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final String alertType;
  final String status; // 'active', 'acknowledged', 'resolved'
  final String? additionalInfo;
  final String? emergencyContact;

  SOSAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.alertType,
    this.status = 'active',
    this.additionalInfo,
    this.emergencyContact,
  });

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      timestamp: DateTime.parse(json['timestamp']),
      alertType: json['alertType'],
      status: json['status'] ?? 'active',
      additionalInfo: json['additionalInfo'],
      emergencyContact: json['emergencyContact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'alertType': alertType,
      'status': status,
      'additionalInfo': additionalInfo,
      'emergencyContact': emergencyContact,
    };
  }

  SOSAlert copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
    String? alertType,
    String? status,
    String? additionalInfo,
    String? emergencyContact,
  }) {
    return SOSAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      alertType: alertType ?? this.alertType,
      status: status ?? this.status,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
