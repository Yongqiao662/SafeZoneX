// Data Models for Walk with Me Feature

import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProfile {
  final String id;
  final String name;
  final String? profilePicture;
  final double rating;
  final int walkCount;  // This was "totalWalks" in some files
  final bool isVerified;
  final String department;
  final int creditScore;
  final LatLng location;
  final int estimatedMinutes;

  const UserProfile({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.rating,
    required this.walkCount,
    this.isVerified = false,
    this.department = '',
    this.creditScore = 0,
    required this.location,
    required this.estimatedMinutes,
  });

  // Add convenience getters for backward compatibility
  int get totalWalks => walkCount;
  String get currentLocation => 'Campus Area'; // For partner profile screen
}

// Using UserProfile instead of separate WalkPartner class
typedef WalkPartner = UserProfile;

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