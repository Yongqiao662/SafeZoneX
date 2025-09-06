// models/safety_report.dart
class SafetyReport {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final String hazardType;
  final String urgencyLevel;
  final String status;
  final String description;
  final String? imageUrl; // Changed from imagePath to imageUrl for web compatibility

  SafetyReport({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.hazardType,
    required this.urgencyLevel,
    required this.status,
    required this.description,
    this.imageUrl,
  });

  SafetyReport copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
    String? hazardType,
    String? urgencyLevel,
    String? status,
    String? description,
    String? imageUrl,
  }) {
    return SafetyReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      hazardType: hazardType ?? this.hazardType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      status: status ?? this.status,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
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
      'hazardType': hazardType,
      'urgencyLevel': urgencyLevel,
      'status': status,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    return SafetyReport(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhone: json['userPhone'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      hazardType: json['hazardType'] as String,
      urgencyLevel: json['urgencyLevel'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}