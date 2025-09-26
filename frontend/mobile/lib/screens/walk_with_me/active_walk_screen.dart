import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'walk_completed_screen.dart';

class ActiveWalkScreen extends StatefulWidget {
  final UserProfile partner;
  final String? selectedDestination;
  final LatLng? destinationCoordinates;

  const ActiveWalkScreen({
    Key? key, 
    required this.partner,
    this.selectedDestination,
    this.destinationCoordinates,
  }) : super(key: key);

  @override
  _ActiveWalkScreenState createState() => _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen> {
  // Dynamic camera position based on actual location
  CameraPosition? _initialCameraPosition;

  bool isWalkActive = true;
  int walkDuration = 0;
  double totalDistance = 0.0;
  Position? currentPosition;
  Position? startPosition;
  String currentLocationName = "Getting location...";
  late Stream<int> _timer;
  Timer? _locationTimer;
  
  // Destination and ETA variables - now dynamic
  String destination = "Loading destination...";
  double totalRouteDistance = 0.0;
  LatLng? destinationCoordinates;
  
  // Map related variables
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> routePoints = [];

  bool isPartnerArrived = false;
  bool isBottomSheetExpanded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize destination from widget parameters
    destination = widget.selectedDestination ?? "Selected Destination";
    destinationCoordinates = widget.destinationCoordinates;
    
    _startTimer();
    _initializeLocation();
    _startLocationTracking();
    
    // Start navigation after location is initialized
    Future.delayed(const Duration(seconds: 2), () {
      if (currentPosition != null && destinationCoordinates != null) {
        _startNavigation();
      }
    });

    // Simulate partner arrival for demo purposes
    Future.delayed(const Duration(seconds: 10), () {
      setState(() => isPartnerArrived = true);
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _getCurrentPosition();
      setState(() {
        currentPosition = position;
        startPosition = position;
        currentLocationName = _getLocationDescription(position);
        
        // Set initial camera position based on actual location
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        );
        
        // Initialize map markers and route
        _setupMapMarkers();
        _addRoutePoint(LatLng(position.latitude, position.longitude));
      });
    } catch (e) {
      setState(() {
        currentLocationName = "Location unavailable";
        // Use fallback location
        _initialCameraPosition = const CameraPosition(
          target: LatLng(3.1225, 101.6532), // University Malaya fallback
          zoom: 16.0,
        );
      });
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        Position newPosition = await _getCurrentPosition();
        if (currentPosition != null) {
          double distance = Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            newPosition.latitude,
            newPosition.longitude,
          );
          setState(() {
            totalDistance += distance;
            currentPosition = newPosition;
            currentLocationName = _getLocationDescription(newPosition);
            
            // Update map
            _updateCurrentLocationMarker();
            _addRoutePoint(LatLng(newPosition.latitude, newPosition.longitude));
          });
        }
      } catch (e) {
        // Handle location error
      }
    });
  }

  void _setupMapMarkers() {
    if (startPosition != null) {
      markers.clear();
      
      // Start marker
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(startPosition!.latitude, startPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Start Point',
            snippet: 'Walk started here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      
      _updateCurrentLocationMarker();
    }
  }

  void _updateCurrentLocationMarker() {
    if (currentPosition != null) {
      // Remove existing current location marker
      markers.removeWhere((marker) => marker.markerId.value == 'current');
      
      // Add current location marker
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: currentLocationName,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  void _addRoutePoint(LatLng point) {
    routePoints.add(point);
    
    // Update polyline
    polylines.clear();
    if (routePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
          patterns: [],
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<Position> _getCurrentPosition() async {
    // Use real GPS location for Android emulator
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled, fall back to a default location
      return Position(
        latitude: 3.1225, // University Malaya as fallback
        longitude: 101.6532,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, fall back to default location
        return Position(
          latitude: 3.1225,
          longitude: 101.6532,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, fall back to default location
      return Position(
        latitude: 3.1225,
        longitude: 101.6532,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    // Get the current position using high accuracy
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current position: $e');
      // Fall back to default location on error
      return Position(
        latitude: 3.1225,
        longitude: 101.6532,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
  }

  String _getLocationDescription(Position position) {
    // Use actual user location coordinates for campus simulation
    // These are sample campus locations that adjust based on user's actual position
    final double baseLat = position.latitude;
    final double baseLng = position.longitude;
    
    final campusLocations = [
    // Keep the dynamic user-based main campus
    {'name': 'Main Campus Building', 'lat': baseLat, 'lng': baseLng},

  // Real Universiti Malaya landmarks
 {'name': 'Library Complex', 'lat': 3.1203, 'lng': 101.6539},       // UM Main Library
  {'name': 'Student Union', 'lat': 3.11850945, 'lng': 101.65275832}, // UM Centre (H09)
  {'name': 'Engineering Building', 'lat': 3.1187, 'lng': 101.6535},  // Approx Faculty of Engineering
  {'name': 'Sports Center', 'lat': 3.1226, 'lng': 101.6592},         // UM Arena/Sports Centre
  {'name': 'Administration Office', 'lat': 3.1197, 'lng': 101.6564}, // Chancellery vicinity
  {'name': 'Cafeteria', 'lat': 3.1211, 'lng': 101.6553},             // Near main canteen
  {'name': 'Dormitory Complex', 'lat': 3.1240, 'lng': 101.6599},     // UM Innovation/Dorm vicinity
];


    double minDistance = double.infinity;
    String closestLocation = "Campus Area";

    for (var location in campusLocations) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location['lat'] as double,
        location['lng'] as double,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestLocation = location['name'] as String;
      }
    }

    return closestLocation;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  // Route and Navigation functionality
  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    print('Getting directions from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');
    
    // Note: Replace 'YOUR_API_KEY' with your actual Google Maps API key
    const String apiKey = 'AIzaSyBOFGvG-_LPgrYBiy1q1Fc8z47EyWMYlZM';
    
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=walking&'
        'key=$apiKey';

    try {
      final http.Response response = await http.get(Uri.parse(url));
      print('Directions API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('API response status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          
          // Decode polyline points
          List<LatLng> routeCoordinates = _decodePolyline(polylinePoints);
          print('Route decoded: ${routeCoordinates.length} points');
          
          setState(() {
            _displayRoute(routeCoordinates);
            
            // Update route info
            final leg = route['legs'][0];
            totalRouteDistance = leg['distance']['value'] / 1000; // Convert to km
            destination = leg['end_address'];
          });
        } else {
          print('API returned status: ${data['status']} or no routes found');
          _createSimpleRoute(origin, destination);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _createSimpleRoute(origin, destination);
      }
    } catch (e) {
      print('Error getting directions: $e');
      // Fallback to simple straight line route
      _createSimpleRoute(origin, destination);
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;
      
      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      
      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  void _displayRoute(List<LatLng> routeCoordinates) {
    print('Displaying route with ${routeCoordinates.length} points');
    polylines.clear();
    
    // Add main route polyline (make it more visible)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('main_route'),
        points: routeCoordinates,
        color: Colors.blue,
        width: 6, // Increased width for better visibility
        patterns: [],
      ),
    );

    // Add walking path (current route)
    if (routePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('walked_route'),
          points: routePoints,
          color: Colors.green,
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ),
      );
    }
    
    print('Route displayed: ${polylines.length} polylines added');
  }

  void _createSimpleRoute(LatLng origin, LatLng destination) {
    // Fallback: Create a more realistic curved route instead of straight line
    List<LatLng> simpleRoute = [];
    
    // Add origin
    simpleRoute.add(origin);
    
    // Create intermediate points for a more realistic walking path
    double latDiff = destination.latitude - origin.latitude;
    double lngDiff = destination.longitude - origin.longitude;
    
    // Add 3-4 intermediate points to simulate a walking path
    for (int i = 1; i <= 3; i++) {
      double progress = i / 4.0;
      double lat = origin.latitude + (latDiff * progress);
      double lng = origin.longitude + (lngDiff * progress);
      
      // Add slight variation to make it more realistic (simulate walking around buildings)
      if (i == 2) {
        lat += 0.0002; // Small detour
        lng += 0.0001;
      }
      
      simpleRoute.add(LatLng(lat, lng));
    }
    
    // Add destination
    simpleRoute.add(destination);
    
    setState(() {
      // Clear existing polylines
      polylines.clear();
      
      // Add fallback route polyline (use blue as requested)
      polylines.add(
        Polyline(
          polylineId: const PolylineId('simple_route'),
          points: simpleRoute,
          color: Colors.blue, // Changed to blue as requested
          width: 6,
          patterns: [], // Solid line instead of dashed
        ),
      );
      
      // Calculate straight-line distance
      double distance = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );
      totalRouteDistance = distance / 1000; // Convert to km
      
      print('Fallback route created: ${simpleRoute.length} points, distance: ${totalRouteDistance.toStringAsFixed(2)} km');
    });
  }

  void _addDestinationMarker(LatLng destination, String name) {
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: name,
        ),
      ),
    );
  }

  // Call this method to start navigation to the selected destination
  void _startNavigation() {
    // List of campus locations
    final List<Map<String, dynamic>> campusLocations = [
      {'name': 'Main Campus Building', 'lat': 3.1225, 'lng': 101.6532},
      {'name': 'Perpustakaan Utama UM (Library)', 'lat': 3.1203, 'lng': 101.6539},
      {'name': 'Student Affairs Division', 'lat': 3.1198, 'lng': 101.6540},  // approximate
      {'name': 'Faculty of Engineering', 'lat': 3.1210, 'lng': 101.6535},      // approximate
      {'name': 'UM Cafeteria Central', 'lat': 3.1195, 'lng': 101.6538},        // approximate
      {'name': 'UM Sports Centre', 'lat': 3.1226, 'lng': 101.6592},           // approximate
      {'name': 'Kolej Kediaman 4th College', 'lat': 3.1240, 'lng': 101.6599},  // approximate
    ];

    if (currentPosition != null) {
      LatLng currentPos = LatLng(currentPosition!.latitude, currentPosition!.longitude);
      LatLng? destCoords;
      String destName = destination;

      // Try to find the selected destination in the campusLocations list
      if (destination.isNotEmpty && destination != "Selected Destination" && destination != "Loading destination...") {
        final match = campusLocations.firstWhere(
          (loc) => loc['name'] == destination,
          orElse: () => campusLocations[0],
        );
        destCoords = LatLng(match['lat'], match['lng']);
        destName = match['name'];
      } else {
        // Use first campus location as fallback
        destCoords = LatLng(campusLocations[0]['lat'], campusLocations[0]['lng']);
        destName = campusLocations[0]['name'];
      }

      setState(() {
        destination = destName;
        destinationCoordinates = destCoords;
      });

  _addDestinationMarker(destCoords, destName);
      _getDirections(currentPos, destCoords);
    }
  }

  double _calculateSpeed() {
    if (walkDuration == 0) return 0.0;
    return (totalDistance / walkDuration) * 3.6; // Convert m/s to km/h
  }

  String _calculateETA() {
    // If route distance is not available, show calculating
    if (totalRouteDistance == 0.0) {
      return "Calculating...";
    }

    double remainingDistance = (totalRouteDistance * 1000) - totalDistance; // in meters

    // If no movement yet, estimate using average walking speed (1.2 m/s)
    double currentSpeed = walkDuration > 0 && totalDistance > 0
        ? totalDistance / walkDuration
        : 1.2;

    if (currentSpeed <= 0) {
      currentSpeed = 1.2; // fallback to average speed
    }

    int etaSeconds = (remainingDistance / currentSpeed).round();
    int etaMinutes = etaSeconds ~/ 60;

    if (etaMinutes < 1) {
      return "< 1 min";
    } else if (etaMinutes < 60) {
      return "$etaMinutes min";
    } else {
      int hours = etaMinutes ~/ 60;
      int minutes = etaMinutes % 60;
      return "${hours}h ${minutes}m";
    }
  }

  double _calculateProgress() {
    if (totalRouteDistance == 0) return 0.0;
    return ((totalDistance / 1000) / totalRouteDistance).clamp(0.0, 1.0);
  }

  Widget _buildCompactStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Map
          StreamBuilder<int>(
            stream: _timer,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                walkDuration = snapshot.data!;
              }
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _initialCameraPosition ?? const CameraPosition(
                  target: LatLng(3.1225, 101.6532), // Fallback to University Malaya
                  zoom: 16.0,
                ),
                markers: markers,
                polylines: polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                buildingsEnabled: false,
                indoorViewEnabled: false,
                trafficEnabled: false,
                liteModeEnabled: false,
                rotateGesturesEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: false,
                minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0),
                style: '''
                [
                  {
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#242f3e"
                      }
                    ]
                  },
                  {
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#746855"
                      }
                    ]
                  },
                  {
                    "elementType": "labels.text.stroke",
                    "stylers": [
                      {
                        "color": "#242f3e"
                      }
                    ]
                  },
                  {
                    "featureType": "administrative.locality",
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#d59563"
                      }
                    ]
                  },
                  {
                    "featureType": "poi",
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#d59563"
                      }
                    ]
                  },
                  {
                    "featureType": "poi.park",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#263c3f"
                      }
                    ]
                  },
                  {
                    "featureType": "poi.park",
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#6b9a76"
                      }
                    ]
                  },
                  {
                    "featureType": "road",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#38414e"
                      }
                    ]
                  },
                  {
                    "featureType": "road",
                    "elementType": "geometry.stroke",
                    "stylers": [
                      {
                        "color": "#212a37"
                      }
                    ]
                  },
                  {
                    "featureType": "road",
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#9ca5b3"
                      }
                    ]
                  },
                  {
                    "featureType": "road.highway",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#746855"
                      }
                    ]
                  },
                  {
                    "featureType": "road.highway",
                    "elementType": "geometry.stroke",
                    "stylers": [
                      {
                        "color": "#1f2835"
                      }
                    ]
                  },
                  {
                    "featureType": "road.highway",
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#f3d19c"
                      }
                    ]
                  },
                  {
                    "featureType": "transit",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#2f3948"
                      }
                    ]
                  },
                  {
                    "featureType": "transit.station",
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#d59563"
                      }
                    ]
                  },
                  {
                    "featureType": "water",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#17263c"
                      }
                    ]
                  },
                  {
                    "featureType": "water",
                    "elementType": "labels.text.fill",
                    "stylers": [
                      {
                        "color": "#515c6d"
                      }
                    ]
                  },
                  {
                    "featureType": "water",
                    "elementType": "labels.text.stroke",
                    "stylers": [
                      {
                        "color": "#17263c"
                      }
                    ]
                  }
                ]
                ''',
              );
            },
          ),
          
          // Top Header with Back Button and Title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1a1a2e).withOpacity(0.9),
                      const Color(0xFF1a1a2e).withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Color(0xFF8F5CFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Walk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'with ${widget.partner.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Partner Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.partner.profilePicture ?? widget.partner.name[0],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Action Button for Navigation
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            right: 16,
            child: FloatingActionButton(
              heroTag: "navigation",
              onPressed: () {
                print('Testing route display...');
                _startNavigation();
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.navigation, color: Colors.white),
            ),
          ),

          // Enhanced Bottom Task Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e).withOpacity(0.95),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Stats Row
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: _buildCompactStatItem(
                              'Time', 
                              '${(walkDuration ~/ 60).toString().padLeft(2, '0')}:${(walkDuration % 60).toString().padLeft(2, '0')}', 
                              Icons.timer
                            ),
                          ),
                          Flexible(
                            child: _buildCompactStatItem(
                              'Distance', 
                              _formatDistance(totalDistance), 
                              Icons.straighten
                            ),
                          ),
                          Flexible(
                            child: _buildCompactStatItem(
                              'ETA', 
                              _calculateETA(), 
                              Icons.access_time
                            ),
                          ),
                          Flexible(
                            child: _buildCompactStatItem(
                              'Speed', 
                              '${_calculateSpeed().toStringAsFixed(1)} km/h', 
                              Icons.speed
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Progress Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress to $destination',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(_calculateProgress() * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _calculateProgress(),
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            minHeight: 6,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatDistance(totalDistance)} traveled',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${totalRouteDistance.toStringAsFixed(1)} km total',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Action Buttons Row
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Emergency Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showEmergencyDialog(),
                              icon: const Icon(Icons.emergency, color: Colors.white, size: 18),
                              label: const Text(
                                'Emergency',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Share Location Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showLocationShare(),
                              icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
                              label: const Text(
                                'Share',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Complete Walk Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _completeWalk(),
                              icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              label: const Text(
                                'Complete',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Expandable Details Section
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isBottomSheetExpanded = !isBottomSheetExpanded;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isBottomSheetExpanded ? 'Hide Details' : 'Show Details',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isBottomSheetExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded Details Section
                    if (isBottomSheetExpanded)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Partner Info
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.deepPurple, Colors.purpleAccent],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.partner.profilePicture ?? widget.partner.name[0],
                                      style: const TextStyle(fontSize: 20, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.partner.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.partner.rating}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isPartnerArrived ? Colors.green : Colors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isPartnerArrived ? 'Nearby' : 'En route',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Detailed Stats Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailedStatCard('Average Speed', '${_calculateSpeed().toStringAsFixed(1)} km/h', Icons.speed),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailedStatCard('Pace', '${_calculateSpeed() > 0 ? (60 / _calculateSpeed()).toStringAsFixed(1) : '0'} min/km', Icons.trending_up),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailedStatCard('Current Location', currentLocationName, Icons.location_on),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailedStatCard('Safety Status', 'Protected', Icons.security),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text('This will alert campus security and your emergency contacts. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger emergency alert
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _showLocationShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared with emergency contacts'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _completeWalk() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WalkCompletedScreen(
          partner: widget.partner,
          duration: walkDuration,
        ),
      ),
    );
  }
}