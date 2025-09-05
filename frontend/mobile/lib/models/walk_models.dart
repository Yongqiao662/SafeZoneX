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

  const CampusLocation({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.building,
  });
}

// University Malaya specific locations
class UMLocations {
  static const Map<String, CampusLocation> locations = {
    'Faculty of Engineering': CampusLocation(
      name: 'Faculty of Engineering',
      category: 'Academic',
      lat: 3.1319,
      lng: 101.6541,
      building: 'Engineering Complex',
    ),
    'Main Library': CampusLocation(
      name: 'Main Library',
      category: 'Academic',
      lat: 3.1218,
      lng: 101.6539,
      building: 'Pustaka Siswa',
    ),
    'KK12 Residential College': CampusLocation(
      name: 'KK12 Residential College',
      category: 'Residential',
      lat: 3.1165,
      lng: 101.6578,
      building: 'KK12',
    ),
    'Faculty of Computer Science': CampusLocation(
      name: 'Faculty of Computer Science',
      category: 'Academic',
      lat: 3.1258,
      lng: 101.6573,
      building: 'FSKTM',
    ),
    'Student Union Building': CampusLocation(
      name: 'Student Union Building',
      category: 'Services',
      lat: 3.1235,
      lng: 101.6521,
      building: 'SUB',
    ),
    'Medical Faculty': CampusLocation(
      name: 'Medical Faculty',
      category: 'Academic',
      lat: 3.1284,
      lng: 101.6498,
      building: 'Medical Complex',
    ),
    'Sports Centre': CampusLocation(
      name: 'Sports Centre',
      category: 'Recreation',
      lat: 3.1189,
      lng: 101.6498,
      building: 'Sports Complex',
    ),
    'DTC (Dewan Tunku Canselor)': CampusLocation(
      name: 'DTC (Dewan Tunku Canselor)',
      category: 'Services',
      lat: 3.1223,
      lng: 101.6547,
      building: 'DTC',
    ),
  };
}
