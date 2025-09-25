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

  const ActiveWalkScreen({Key? key, required this.partner}) : super(key: key);

  @override
  _ActiveWalkScreenState createState() => _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen> {
  // University Malaya campus center coordinates (same as safety zone map)
  static const CameraPosition _universityMalaya = CameraPosition(
    target: LatLng(3.1225, 101.6532),
    zoom: 16.0,
  );

  bool isWalkActive = true;
  int walkDuration = 0;
  double totalDistance = 0.0;
  Position? currentPosition;
  Position? startPosition;
  String currentLocationName = "Getting location...";
  Timer? _walkTimer;
  Timer? _locationTimer;
  
  // Destination and ETA variables
  String destination = "Student Center"; // Default destination
  double totalRouteDistance = 2.5; // Total estimated distance in km
  
  // Map related variables
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> routePoints = [];

  bool isPartnerArrived = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeLocation();
    _startLocationTracking();
    
    // Start navigation after a short delay to allow location initialization
    Future.delayed(const Duration(seconds: 3), () {
      _startNavigation();
    });

    // Simulate partner arrival for demo purposes
    Future.delayed(const Duration(seconds: 10), () {
      setState(() => isPartnerArrived = true);
    });
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _walkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        walkDuration = timer.tick;
      });
    });
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _getCurrentPosition();
      setState(() {
        currentPosition = position;
        startPosition = position;
        currentLocationName = _getLocationDescription(position);
        
        // Initialize map markers and route
        _setupMapMarkers();
        _addRoutePoint(LatLng(position.latitude, position.longitude));
      });
    } catch (e) {
      setState(() {
        currentLocationName = "Location unavailable";
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
          color: Colors.green, // Keep your original green color for walked path
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
    // For testing purposes, return a mock location at University Malaya
    // Comment out this block and uncomment the real GPS code below when deploying
    
    // Mock position at UM campus for testing
    return Position(
      latitude: 3.1225, // UM campus center
      longitude: 101.6532, // UM campus center
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    /* Uncomment this for real GPS location:
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
    */
  }

  String _getLocationDescription(Position position) {
    // Use actual user location coordinates for campus simulation
    // These are sample campus locations that adjust based on user's actual position
    final double baseLat = position.latitude;
    final double baseLng = position.longitude;
    
    final campusLocations = [
      {'name': 'Main Campus Building', 'lat': baseLat + 0.0001, 'lng': baseLng + 0.0001},
      {'name': 'Library Complex', 'lat': baseLat + 0.0002, 'lng': baseLng + 0.0002},
      {'name': 'Student Union', 'lat': baseLat - 0.0003, 'lng': baseLng + 0.0005},
      {'name': 'Engineering Building', 'lat': baseLat + 0.0004, 'lng': baseLng + 0.0002},
      {'name': 'Sports Center', 'lat': baseLat - 0.0008, 'lng': baseLng - 0.0005},
      {'name': 'Administration Office', 'lat': baseLat + 0.0005, 'lng': baseLng - 0.0003},
      {'name': 'Cafeteria', 'lat': baseLat - 0.0002, 'lng': baseLng + 0.0003},
      {'name': 'Dormitory Complex', 'lat': baseLat + 0.0007, 'lng': baseLng - 0.0010},
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
    
    // Add main route polyline (blue for planned route)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('main_route'),
        points: routeCoordinates,
        color: Colors.blue,
        width: 6,
        patterns: [],
      ),
    );

    // Add walking path (current route) - keep your green color
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
          color: Colors.blue,
          width: 6,
          patterns: [],
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

  // Call this method to start navigation to a specific destination
  void _startNavigation() {
    if (currentPosition != null) {
      // Example destinations within University Malaya campus
      LatLng currentPos = LatLng(currentPosition!.latitude, currentPosition!.longitude);
      
      // Sample destinations (you can make this dynamic)
      List<Map<String, dynamic>> destinations = [
        {'name': 'UM Main Library', 'position': const LatLng(3.1235, 101.6545)},
        {'name': 'Student Center', 'position': const LatLng(3.1220, 101.6530)},
        {'name': 'Engineering Faculty', 'position': const LatLng(3.1240, 101.6555)},
        {'name': 'Sports Complex', 'position': const LatLng(3.1265, 101.6525)},
      ];
      
      // For demo, navigate to the Student Center
      LatLng destination = destinations[1]['position'];
      String destinationName = destinations[1]['name'];
      
      // Add destination marker
      _addDestinationMarker(destination, destinationName);
      
      // Get directions
      _getDirections(currentPos, destination);
    }
  }

  double _calculateSpeed() {
    if (walkDuration == 0) return 0.0;
    return (totalDistance / walkDuration) * 3.6; // Convert m/s to km/h
  }

  String _calculateETA() {
    if (totalDistance == 0 || walkDuration == 0) {
      return "3 min";
    }
    
    double remainingDistance = (totalRouteDistance * 1000) - totalDistance; // in meters
    double currentSpeed = totalDistance / walkDuration; // m/s
    
    if (currentSpeed <= 0) {
      return "3 min";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f1e),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Map - Full screen
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _universityMalaya,
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
              ),
              
              // Top Dashboard - Keep your original design
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1a1a2e).withOpacity(0.9),
                      const Color(0xFF1a1a2e).withOpacity(0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.directions_walk,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Active Walk',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Grab-style Bottom Sheet - Dark Theme
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1a1a2e), // Dark background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Trip Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Route Info
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      currentLocationName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Route line
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey[600],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Destination
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.red, width: 2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      destination,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _calculateETA(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Divider
                              Container(
                                height: 1,
                                color: Colors.grey[700],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Partner Info Card - Dark theme
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16213e), // Darker shade
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                child: Row(
                                  children: [
                                    // Partner Avatar
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Partner Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.partner.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
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
                                                  fontSize: 14,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                'Walking Partner',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Call/Message buttons
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1a1a2e),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.grey[600]!),
                                          ),
                                          child: IconButton(
                                            onPressed: () => _showContactOptions(),
                                            icon: const Icon(
                                              Icons.phone,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1a1a2e),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.grey[600]!),
                                          ),
                                          child: IconButton(
                                            onPressed: () => _showContactOptions(),
                                            icon: const Icon(
                                              Icons.message,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Progress and Stats Row - Dark theme
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16213e),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildMiniStat('Distance', _formatDistance(totalDistance)),
                                        _buildMiniStat('Time', Text(
                                          '${(walkDuration ~/ 60).toString().padLeft(2, '0')}:${(walkDuration % 60).toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        )),
                                        _buildMiniStat('Speed', '${_calculateSpeed().toStringAsFixed(1)} km/h'),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Progress Bar
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Progress',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                            Text(
                                              '${(_calculateProgress() * 100).toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: _calculateProgress(),
                                          backgroundColor: Colors.grey[700],
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                          minHeight: 6,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Action Buttons - Dark theme
                              Column(
                                children: [
                                  // Emergency and Share Location buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: TextButton.icon(
                                            onPressed: () => _showEmergencyDialog(),
                                            icon: const Icon(Icons.warning, color: Colors.white, size: 20),
                                            label: const Text(
                                              'Emergency',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16213e),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[600]!),
                                          ),
                                          child: TextButton.icon(
                                            onPressed: () => _showLocationShare(),
                                            icon: const Icon(Icons.location_on, color: Colors.white, size: 20),
                                            label: const Text(
                                              'Share Location',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Complete Walk button
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () => _completeWalk(),
                                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      label: const Text(
                                        'Complete Walk',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
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
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        value is Widget ? value : Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showContactOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contacting ${widget.partner.name}...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
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
            child: const Text('Send Alert', style: TextStyle(color: Colors.white)),
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