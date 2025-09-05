// Data Models for Walk with Me Feature

class UserProfile {
  final String id;
  final String name;
  final String profilePicture;
  final int creditScore;
  final String department;
  final double currentLat;
  final double currentLng;
  final String currentLocation;
  final bool isVerified;
  final double rating;
  final int walkCount;

  UserProfile({
    required this.id,
    required this.name,
    required this.profilePicture,
    required this.creditScore,
    required this.department,
    required this.currentLat,
    required this.currentLng,
    required this.currentLocation,
    this.isVerified = false,
    this.rating = 0.0,
    this.walkCount = 0,
  });
}

class WalkRequest {
  final String id;
  final String userId;
  final String destination;
  final double destLat;
  final double destLng;
  final DateTime departureTime;
  final int maxWalkmates;
  final String walkSpeed; // slow, normal, fast
  final List<String> preferences;
  final bool isActive;

  WalkRequest({
    required this.id,
    required this.userId,
    required this.destination,
    required this.destLat,
    required this.destLng,
    required this.departureTime,
    required this.maxWalkmates,
    required this.walkSpeed,
    required this.preferences,
    this.isActive = true,
  });
}

class CampusLocation {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final String building;

  CampusLocation({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.building,
  });
}
