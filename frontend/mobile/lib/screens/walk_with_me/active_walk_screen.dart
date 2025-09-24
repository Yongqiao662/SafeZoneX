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
  late Stream<int> _timer;
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
      return "Calculating...";
    }
    
    double remainingDistance = (totalRouteDistance * 1000) - totalDistance; // in meters
    double currentSpeed = totalDistance / walkDuration; // m/s
    
    if (currentSpeed <= 0) {
      return "Calculating...";
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

  Widget _buildStatCard(String label, String value, IconData icon) {
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
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: widget.partner.profilePicture != null
              ? NetworkImage(widget.partner.profilePicture!)
              : null,
          child: widget.partner.profilePicture == null
              ? Text(widget.partner.name[0])
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.partner.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.partner.rating}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Testing route display...');
          _startNavigation();
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.navigation),
      ),
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
          child: Column(
            children: [
              // Title Section - Matching Home page style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              // Content section
              Expanded(
                child: StreamBuilder<int>(
                  stream: _timer,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      walkDuration = snapshot.data!;
                    }
                    return _buildWalkInterface();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalkInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Real-time Map with Route
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _universityMalaya, // Use University Malaya coordinates
                markers: markers,
                polylines: polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // Disable to reduce processing
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: false, // Disable to reduce image processing
                mapToolbarEnabled: false,
                buildingsEnabled: false, // Disable to reduce buffer usage
                indoorViewEnabled: false, // Improves performance
                trafficEnabled: false, // Reduces lag
                liteModeEnabled: false, // Keep full functionality
                rotateGesturesEnabled: false, // Disable to reduce processing
                scrollGesturesEnabled: true, // Allow panning
                zoomGesturesEnabled: true, // Allow pinch zoom
                tiltGesturesEnabled: false, // Disable 3D tilt to reduce processing
                minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0), // Reasonable zoom limits
                // Dark mode styling (same as safety zone map)
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
            ),
          ),
          const SizedBox(height: 20),
          // Partner and Walk Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Safe Walk to $destination',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'with ${widget.partner.name}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          widget.partner.profilePicture ?? widget.partner.name[0],
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.directions_walk,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          '👤',
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${(_calculateProgress() * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _calculateProgress(),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Enhanced Stats Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Time', '${(walkDuration ~/ 60).toString().padLeft(2, '0')}:${(walkDuration % 60).toString().padLeft(2, '0')}', Icons.timer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('ETA', _calculateETA(), Icons.access_time),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Distance', _formatDistance(totalDistance), Icons.straighten),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('Total', '${totalRouteDistance.toStringAsFixed(1)} km', Icons.location_on),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Speed', '${_calculateSpeed().toStringAsFixed(1)} km/h', Icons.speed),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('Pace', '${_calculateSpeed() > 0 ? (60 / _calculateSpeed()).toStringAsFixed(1) : '0'} min/km', Icons.trending_up),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Safety Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Safety Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEmergencyDialog(),
                        icon: const Icon(Icons.emergency, color: Colors.white),
                        label: const Text(
                          'Emergency',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showLocationShare(),
                        icon: const Icon(Icons.location_on, color: Colors.white),
                        label: const Text(
                          'Share Location',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _completeWalk(),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'Complete Walk',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
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
