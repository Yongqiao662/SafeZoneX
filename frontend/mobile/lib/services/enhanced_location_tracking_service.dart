import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class EnhancedLocationTrackingService extends ChangeNotifier {
  static final EnhancedLocationTrackingService _instance = EnhancedLocationTrackingService._internal();
  factory EnhancedLocationTrackingService() => _instance;
  EnhancedLocationTrackingService._internal();

  // Google Maps Integration
  String? _googleMapsApiKey;
  Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  Set<Circle> _safeZoneCircles = {};
  
  // Current location data
  Position? _currentPosition;
  String? _currentAddress;
  String? _locationError;
  
  // Tracking state
  bool _isTracking = false;
  bool _isEmergencyTracking = false;
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = false;
  bool _isInSafeZone = false;
  
  // Streaming and listeners
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _periodicLocationTimer;
  Timer? _emergencyBeaconTimer;
  
  // Safe zones and security features
  List<SafeZone> _safeZones = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<LocationHistoryPoint> _locationHistory = [];
  
  // Server/Firebase integration for real-time tracking
  String? _backendApiUrl;
  String? _trackingSessionId;
  Timer? _serverSyncTimer;

  // Location tracking settings - Enhanced for real-time accuracy
  final LocationSettings _normalLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy
    distanceFilter: 1, // Update every 1 meter
    timeLimit: const Duration(seconds: 10),
  );
  
  final LocationSettings _emergencyLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation, // Maximum precision
    distanceFilter: 0, // Update on any movement
    timeLimit: const Duration(seconds: 3), // Faster response
  );

  final LocationSettings _highAccuracySettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 0,
    timeLimit: const Duration(seconds: 2),
  );

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get locationError => _locationError;
  bool get isTracking => _isTracking;
  bool get isEmergencyTracking => _isEmergencyTracking;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isInSafeZone => _isInSafeZone;
  List<SafeZone> get safeZones => _safeZones;
  Set<Marker> get markers => _markers;
  Set<Circle> get safeZoneCircles => _safeZoneCircles;
  List<LocationHistoryPoint> get locationHistory => _locationHistory;

  // Callbacks
  Function(Position position, String? address)? onLocationUpdate;
  Function(String error)? onLocationError;
  Function(bool isEmergency)? onTrackingStateChanged;
  Function(bool isInSafeZone)? onSafeZoneStatusChanged;
  Function(Map<String, dynamic> emergencyData)? onEmergencyTriggered;

  /// Initialize with Google Maps API key and backend URL
  Future<bool> initialize({
    required String googleMapsApiKey,
    String? backendApiUrl,
  }) async {
    _googleMapsApiKey = googleMapsApiKey;
    _backendApiUrl = backendApiUrl;

    try {
      // Load saved data
      await _loadSavedData();
      
      // Initialize location permissions and services
      final hasPermission = await _requestLocationPermissions();
      if (!hasPermission) {
        _locationError = 'Location permission denied';
        notifyListeners();
        return false;
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      _isLocationServiceEnabled = isServiceEnabled;
      
      if (!isServiceEnabled) {
        _locationError = 'Location services are disabled';
        notifyListeners();
        return false;
      }

      // Get initial location
      await getCurrentLocation();
      
      // Load safe zones from Google Places API if available
      await _loadSafeZonesFromGooglePlaces();
      
      _locationError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _locationError = 'Failed to initialize: $e';
      notifyListeners();
      return false;
    }
  }

  /// Enhanced permission handling
  Future<bool> _requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permissions permanently denied';
        return false;
      }
      
      if (permission == LocationPermission.denied) {
        _locationError = 'Location permissions denied';
        return false;
      }

      // Request background location for continuous tracking
      if (Platform.isAndroid) {
        await Permission.locationAlways.request();
      }
      
      _isLocationPermissionGranted = true;
      return true;
    } catch (e) {
      _locationError = 'Error requesting permissions: $e';
      return false;
    }
  }

  /// Get current location with immediate high accuracy
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      if (!_isLocationPermissionGranted) {
        final hasPermission = await _requestLocationPermissions();
        if (!hasPermission) return null;
      }

      // Use high accuracy settings for immediate location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 8),
        forceAndroidLocationManager: false, // Use GPS provider
      );
      
      _currentPosition = position;
      
      // Update address efficiently (don't block location update)
      _updateAddressWithGoogleGeocoding(position).catchError((e) {
        debugPrint('Address lookup error: $e');
      });
      
      // Update map marker efficiently
      _updateCurrentLocationMarker();
      
      // Check safe zone status
      _checkSafeZoneStatus();
      
      // Add to location history (limit frequency to reduce lag)
      if (forceRefresh || _shouldAddToHistory(position)) {
        _addToLocationHistory(position);
      }
      
      // Efficient server sync (don't wait for response)
      if (_backendApiUrl != null && _isTracking) {
        _syncLocationWithServer(position).catchError((e) {
          debugPrint('Server sync error: $e');
        });
      }
      
      // Notify listeners efficiently
      onLocationUpdate?.call(position, _currentAddress);
      
      // Use post-frame callback to prevent lag
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      
      return position;
    } catch (e) {
      _locationError = 'Error getting location: $e';
      onLocationError?.call(_locationError!);
      notifyListeners();
      return null;
    }
  }

  /// Check if we should add to history (reduce frequency for performance)
  bool _shouldAddToHistory(Position newPosition) {
    if (_locationHistory.isEmpty) return true;
    
    final lastPoint = _locationHistory.last;
    final timeDiff = DateTime.now().difference(lastPoint.timestamp);
    
    // Add if 30 seconds passed or moved significant distance
    return timeDiff.inSeconds > 30 || 
           Geolocator.distanceBetween(
             lastPoint.position.latitude, 
             lastPoint.position.longitude,
             newPosition.latitude, 
             newPosition.longitude,
           ) > 10; // 10 meter threshold
  }

  /// Enhanced address lookup using Google Geocoding API
  Future<void> _updateAddressWithGoogleGeocoding(Position position) async {
    try {
      if (_googleMapsApiKey == null) {
        // Fallback to native geocoding
        await _updateAddressFromPosition(position);
        return;
      }

      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${position.latitude},${position.longitude}'
          '&key=$_googleMapsApiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          _currentAddress = data['results'][0]['formatted_address'];
        }
      } else {
        // Fallback to native geocoding
        await _updateAddressFromPosition(position);
      }
    } catch (e) {
      debugPrint('Google Geocoding error: $e');
      await _updateAddressFromPosition(position);
    }
  }

  /// Fallback address lookup
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
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (e) {
      _currentAddress = 'Address unavailable';
    }
  }

  /// Start enhanced tracking with performance optimization
  Future<bool> startTracking({bool isEmergency = false}) async {
    try {
      if (_isTracking) return true;

      if (!_isLocationPermissionGranted) {
        final initialized = await initialize(
          googleMapsApiKey: _googleMapsApiKey ?? '',
        );
        if (!initialized) return false;
      }

      _isEmergencyTracking = isEmergency;
      final settings = isEmergency ? _emergencyLocationSettings : _normalLocationSettings;
      
      // Create tracking session
      _trackingSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get immediate location first
      await getCurrentLocation(forceRefresh: true);
      
      // Start optimized position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (Position position) async {
          _currentPosition = position;
          
          // Efficient address update (async, don't block)
          _updateAddressWithGoogleGeocoding(position).catchError((e) {
            debugPrint('Address update error: $e');
          });
          
          // Immediate UI updates
          _updateCurrentLocationMarker();
          _checkSafeZoneStatus();
          
          // Throttled history updates
          if (_shouldAddToHistory(position)) {
            _addToLocationHistory(position);
          }
          
          // Background server sync
          if (isEmergency && _backendApiUrl != null) {
            _syncLocationWithServer(position).catchError((e) {
              debugPrint('Emergency sync error: $e');
            });
          }
          
          // Efficient callback
          onLocationUpdate?.call(position, _currentAddress);
          
          // Post-frame UI update to prevent lag
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        },
        onError: (error) {
          _locationError = 'Tracking error: $error';
          onLocationError?.call(_locationError!);
        },
      );

      // Optimized server sync timer
      if (_backendApiUrl != null) {
        final syncInterval = isEmergency ? 10 : 60; // Reduced frequency
        _serverSyncTimer = Timer.periodic(
          Duration(seconds: syncInterval),
          (_) {
            if (_currentPosition != null) {
              _syncLocationWithServer(_currentPosition!).catchError((e) {
                debugPrint('Periodic sync error: $e');
              });
            }
          },
        );
      }

      // Emergency beacon with reduced frequency
      if (isEmergency) {
        _emergencyBeaconTimer = Timer.periodic(
          const Duration(seconds: 15), // Reduced from 10 to 15 seconds
          (_) => _sendEmergencyBeacon().catchError((e) {
            debugPrint('Emergency beacon error: $e');
          }),
        );
      }

      _isTracking = true;
      onTrackingStateChanged?.call(isEmergency);
      
      // Background state save
      _saveTrackingState().catchError((e) {
        debugPrint('Save state error: $e');
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      _locationError = 'Failed to start tracking: $e';
      onLocationError?.call(_locationError!);
      notifyListeners();
      return false;
    }
  }

  /// Stop all tracking
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    _periodicLocationTimer?.cancel();
    _periodicLocationTimer = null;
    
    _serverSyncTimer?.cancel();
    _serverSyncTimer = null;
    
    _emergencyBeaconTimer?.cancel();
    _emergencyBeaconTimer = null;
    
    _isTracking = false;
    _isEmergencyTracking = false;
    _trackingSessionId = null;
    
    onTrackingStateChanged?.call(false);
    
    // Save state
    _saveTrackingState();
    
    notifyListeners();
  }

  /// Load safe zones from Google Places API
  Future<void> _loadSafeZonesFromGooglePlaces() async {
    if (_googleMapsApiKey == null || _currentPosition == null) return;

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&radius=2000'
          '&type=police|hospital|fire_station'
          '&key=$_googleMapsApiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          _safeZones = (data['results'] as List).map((place) {
            return SafeZone(
              id: place['place_id'],
              name: place['name'],
              latitude: place['geometry']['location']['lat'].toDouble(),
              longitude: place['geometry']['location']['lng'].toDouble(),
              description: place['types'].join(', '),
              radius: _getSafeZoneRadius(place['types']),
              isActive: true,
            );
          }).toList();
          
          _updateSafeZoneCircles();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading safe zones: $e');
    }
  }

  double _getSafeZoneRadius(List<dynamic> types) {
    if (types.contains('police')) return 200;
    if (types.contains('hospital')) return 300;
    if (types.contains('fire_station')) return 150;
    return 100;
  }

  /// Update map markers
  void _updateCurrentLocationMarker() {
    if (_currentPosition == null) return;

    _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
    
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _isEmergencyTracking ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
        ),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: _currentAddress ?? 'Current location',
        ),
      ),
    );
    
    // Add safe zone markers
    for (final zone in _safeZones) {
      _markers.add(
        Marker(
          markerId: MarkerId(zone.id),
          position: LatLng(zone.latitude, zone.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: zone.name,
            snippet: zone.description,
          ),
        ),
      );
    }
  }

  /// Update safe zone circles
  void _updateSafeZoneCircles() {
    _safeZoneCircles = _safeZones.map((zone) {
      return Circle(
        circleId: CircleId(zone.id),
        center: LatLng(zone.latitude, zone.longitude),
        radius: zone.radius,
        fillColor: Colors.green.withOpacity(0.2),
        strokeColor: Colors.green,
        strokeWidth: 2,
      );
    }).toSet();
  }

  /// Check if user is in safe zone
  void _checkSafeZoneStatus() {
    if (_currentPosition == null) return;

    final wasInSafeZone = _isInSafeZone;
    _isInSafeZone = _safeZones.any((zone) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        zone.latitude,
        zone.longitude,
      );
      return distance <= zone.radius;
    });

    if (wasInSafeZone != _isInSafeZone) {
      onSafeZoneStatusChanged?.call(_isInSafeZone);
    }
  }

  /// Add location to history
  void _addToLocationHistory(Position position) {
    _locationHistory.add(
      LocationHistoryPoint(
        position: position,
        address: _currentAddress,
        timestamp: DateTime.now(),
        isEmergencyMode: _isEmergencyTracking,
      ),
    );

    // Keep only last 1000 points
    if (_locationHistory.length > 1000) {
      _locationHistory.removeAt(0);
    }
  }

  /// Sync location with backend server
  Future<void> _syncLocationWithServer(Position? position) async {
    if (_backendApiUrl == null || position == null) return;

    try {
      final data = {
        'session_id': _trackingSessionId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.toIso8601String(),
        'address': _currentAddress,
        'is_emergency': _isEmergencyTracking,
        'is_in_safe_zone': _isInSafeZone,
      };

      await http.post(
        Uri.parse('$_backendApiUrl/api/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
    } catch (e) {
      debugPrint('Server sync error: $e');
    }
  }

  /// Send emergency beacon
  Future<void> _sendEmergencyBeacon() async {
    if (!_isEmergencyTracking || _currentPosition == null) return;

    final emergencyData = {
      'type': 'emergency_beacon',
      'location': {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'accuracy': _currentPosition!.accuracy,
        'address': _currentAddress,
      },
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': _trackingSessionId,
    };

    // Notify emergency contacts
    for (final contact in _emergencyContacts) {
      // Send SMS/notification to emergency contacts
      _notifyEmergencyContact(contact, emergencyData);
    }

    onEmergencyTriggered?.call(emergencyData);
  }

  /// Notify emergency contact
  Future<void> _notifyEmergencyContact(
    EmergencyContact contact,
    Map<String, dynamic> emergencyData,
  ) async {
    // Implementation for SMS/Push notification
    // This would integrate with your notification service
  }

  /// Load saved data
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    // Load safe zones, emergency contacts, etc.
  }

  /// Save tracking state
  Future<void> _saveTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', _isTracking);
    await prefs.setBool('is_emergency_tracking', _isEmergencyTracking);
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

// Enhanced models
class SafeZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final double radius;
  final bool isActive;

  SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.radius = 100.0,
    this.isActive = true,
  });
}

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final bool isActive;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.isActive = true,
  });
}

class LocationHistoryPoint {
  final Position position;
  final String? address;
  final DateTime timestamp;
  final bool isEmergencyMode;

  LocationHistoryPoint({
    required this.position,
    this.address,
    required this.timestamp,
    this.isEmergencyMode = false,
  });
}
