import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class LocationTrackingService extends ChangeNotifier {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  // Current location data
  Position? _currentPosition;
  String? _currentAddress;
  String? _locationError;
  
  // Tracking state
  bool _isTracking = false;
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = false;
  
  // Streaming and listeners
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _periodicLocationTimer;
  
  // Location tracking settings
  final LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );
  
  // Emergency tracking settings (more frequent updates)
  final LocationSettings _emergencyLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 5, // Update every 5 meters
  );

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get locationError => _locationError;
  bool get isTracking => _isTracking;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;

  // Callbacks for location updates
  Function(Position position, String? address)? onLocationUpdate;
  Function(String error)? onLocationError;
  Function(bool isEmergency)? onTrackingStateChanged;

  /// Initialize location service and request permissions
  Future<bool> initialize() async {
    try {
      // Check and request location permissions
      final hasPermission = await _requestLocationPermissions();
      if (!hasPermission) {
        _locationError = 'Location permission denied';
        notifyListeners();
        return false;
      }

      // Check if location services are enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      _isLocationServiceEnabled = isServiceEnabled;
      
      if (!isServiceEnabled) {
        _locationError = 'Location services are disabled. Please enable location services.';
        notifyListeners();
        return false;
      }

      // Get initial location
      await getCurrentLocation();
      
      _locationError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _locationError = 'Failed to initialize location service: $e';
      notifyListeners();
      return false;
    }
  }

  /// Request location permissions with proper handling
  Future<bool> _requestLocationPermissions() async {
    try {
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately
        _locationError = 'Location permissions are permanently denied. Please enable them in settings.';
        return false;
      }
      
      if (permission == LocationPermission.denied) {
        _locationError = 'Location permissions are denied.';
        return false;
      }
      
      // Also request background location for tracking
      if (Platform.isAndroid) {
        final backgroundPermission = await Permission.locationAlways.request();
        if (backgroundPermission.isDenied) {
          // Still allow basic functionality with when-in-use permission
          debugPrint('Background location permission denied, using when-in-use permission');
        }
      }
      
      _isLocationPermissionGranted = true;
      return true;
    } catch (e) {
      _locationError = 'Error requesting location permissions: $e';
      return false;
    }
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      if (!_isLocationPermissionGranted) {
        final hasPermission = await _requestLocationPermissions();
        if (!hasPermission) return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      
      // Get address from coordinates
      await _updateAddressFromPosition(position);
      
      // Notify callbacks
      onLocationUpdate?.call(position, _currentAddress);
      notifyListeners();
      
      return position;
    } catch (e) {
      _locationError = 'Error getting current location: $e';
      onLocationError?.call(_locationError!);
      notifyListeners();
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startTracking({bool isEmergency = false}) async {
    try {
      if (_isTracking) {
        debugPrint('Location tracking is already active');
        return true;
      }

      // Initialize if not done
      if (!_isLocationPermissionGranted) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      // Choose location settings based on emergency mode
      final settings = isEmergency ? _emergencyLocationSettings : _locationSettings;
      
      // Start position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _updateAddressFromPosition(position);
          onLocationUpdate?.call(position, _currentAddress);
          notifyListeners();
        },
        onError: (error) {
          _locationError = 'Location tracking error: $error';
          onLocationError?.call(_locationError!);
          notifyListeners();
        },
      );

      // Set up periodic updates as backup (every 30 seconds in normal mode, 10 seconds in emergency)
      final interval = isEmergency ? Duration(seconds: 10) : Duration(seconds: 30);
      _periodicLocationTimer = Timer.periodic(interval, (timer) async {
        await getCurrentLocation();
      });

      _isTracking = true;
      onTrackingStateChanged?.call(isEmergency);
      notifyListeners();
      
      debugPrint('Location tracking started (Emergency mode: $isEmergency)');
      return true;
    } catch (e) {
      _locationError = 'Failed to start location tracking: $e';
      onLocationError?.call(_locationError!);
      notifyListeners();
      return false;
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    _periodicLocationTimer?.cancel();
    _periodicLocationTimer = null;
    
    _isTracking = false;
    onTrackingStateChanged?.call(false);
    notifyListeners();
    
    debugPrint('Location tracking stopped');
  }

  /// Update address from position coordinates
  Future<void> _updateAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = [
          placemark.name,
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.postalCode,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      _currentAddress = 'Address unavailable';
    }
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if user is within a safe zone
  bool isWithinSafeZone(List<SafeZone> safeZones, {double radiusMeters = 100}) {
    if (_currentPosition == null) return false;
    
    for (final zone in safeZones) {
      final distance = calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        zone.latitude,
        zone.longitude,
      );
      
      if (distance <= radiusMeters) {
        return true;
      }
    }
    return false;
  }

  /// Get location data for emergency alerts
  Map<String, dynamic> getEmergencyLocationData() {
    return {
      'latitude': _currentPosition?.latitude ?? 0.0,
      'longitude': _currentPosition?.longitude ?? 0.0,
      'accuracy': _currentPosition?.accuracy ?? 0.0,
      'altitude': _currentPosition?.altitude ?? 0.0,
      'speed': _currentPosition?.speed ?? 0.0,
      'heading': _currentPosition?.heading ?? 0.0,
      'timestamp': _currentPosition?.timestamp.toIso8601String() ?? DateTime.now().toIso8601String(),
      'address': _currentAddress ?? 'Address unavailable',
      'isTracking': _isTracking,
    };
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Dispose resources
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Safe zone model for location checking
class SafeZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final bool isActive;

  SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.isActive = true,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'isActive': isActive,
    };
  }
}
