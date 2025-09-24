import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'models.dart';
import 'active_walk_screen.dart';

class PartnerWaitingScreen extends StatefulWidget {
  final UserProfile partner;
  final String destination;
  final DateTime departureTime;
  final String message;

  const PartnerWaitingScreen({
    Key? key,
    required this.partner,
    required this.destination,
    required this.departureTime,
    required this.message,
  }) : super(key: key);

  @override
  _PartnerWaitingScreenState createState() => _PartnerWaitingScreenState();
}

class _PartnerWaitingScreenState extends State<PartnerWaitingScreen> with TickerProviderStateMixin {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  
  // Location tracking
  Position? myCurrentPosition;
  Position? partnerCurrentPosition;
  Timer? locationUpdateTimer;
  
  // Animation controllers
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Status tracking
  String partnerStatus = 'Looking for your partner...';
  int estimatedArrivalMinutes = 0;
  double distanceToPartner = 0.0;
  bool partnerFound = false;
  bool partnerAccepted = false;
  bool partnerOnTheWay = false;
  
  // University Malaya center coordinates
  static const LatLng _universityMalayaCenter = LatLng(3.1225, 101.6532);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocation();
    _startLocationTracking();
    _simulatePartnerResponse();
  }

  @override
  void dispose() {
    locationUpdateTimer?.cancel();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimationController.repeat(reverse: true);
    _slideAnimationController.forward();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _getCurrentPosition();
      setState(() {
        myCurrentPosition = position;
      });
      _updateMapMarkers();
    } catch (e) {
      print('Error getting location: $e');
      // Use default UM location for demo
      setState(() {
        myCurrentPosition = Position(
          latitude: _universityMalayaCenter.latitude,
          longitude: _universityMalayaCenter.longitude,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      });
      _updateMapMarkers();
    }
  }

  void _startLocationTracking() {
    locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateLocations();
    });
  }

  Future<void> _updateLocations() async {
    try {
      // Update my location
      Position newPosition = await _getCurrentPosition();
      setState(() {
        myCurrentPosition = newPosition;
      });
      
      // Simulate partner location updates
      if (partnerFound && partnerAccepted) {
        _updatePartnerLocation();
      }
      
      _updateMapMarkers();
      _calculateDistance();
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void _updatePartnerLocation() {
    if (partnerCurrentPosition == null) return;
    
    // Simulate partner moving towards user
    final Random random = Random();
    double latOffset = (random.nextDouble() - 0.5) * 0.0002; // Small random movement
    double lngOffset = (random.nextDouble() - 0.5) * 0.0002;
    
    // Move slightly towards user location
    if (myCurrentPosition != null) {
      double directionLat = (myCurrentPosition!.latitude - partnerCurrentPosition!.latitude) * 0.1;
      double directionLng = (myCurrentPosition!.longitude - partnerCurrentPosition!.longitude) * 0.1;
      
      setState(() {
        partnerCurrentPosition = Position(
          latitude: partnerCurrentPosition!.latitude + directionLat + latOffset,
          longitude: partnerCurrentPosition!.longitude + directionLng + lngOffset,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      });
    }
  }

  void _calculateDistance() {
    if (myCurrentPosition != null && partnerCurrentPosition != null) {
      double distance = Geolocator.distanceBetween(
        myCurrentPosition!.latitude,
        myCurrentPosition!.longitude,
        partnerCurrentPosition!.latitude,
        partnerCurrentPosition!.longitude,
      );
      
      setState(() {
        distanceToPartner = distance;
        // Estimate arrival time based on walking speed (average 1.2 m/s)
        estimatedArrivalMinutes = (distance / 1.2 / 60).ceil();
      });
    }
  }

  void _updateMapMarkers() {
    markers.clear();
    
    // Add my location marker
    if (myCurrentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(myCurrentPosition!.latitude, myCurrentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    }
    
    // Add partner location marker (if found and accepted)
    if (partnerCurrentPosition != null && partnerAccepted) {
      markers.add(
        Marker(
          markerId: const MarkerId('partner_location'),
          position: LatLng(partnerCurrentPosition!.latitude, partnerCurrentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.partner.name,
            snippet: 'Your walking partner',
          ),
        ),
      );
      
      // Draw line between users
      _drawRouteBetweenUsers();
    }
    
    // Add destination marker
    LatLng destinationLatLng = _getDestinationCoordinates(widget.destination);
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.destination,
        ),
      ),
    );
  }

  void _drawRouteBetweenUsers() {
    if (myCurrentPosition != null && partnerCurrentPosition != null) {
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('user_connection'),
          points: [
            LatLng(myCurrentPosition!.latitude, myCurrentPosition!.longitude),
            LatLng(partnerCurrentPosition!.latitude, partnerCurrentPosition!.longitude),
          ],
          color: Colors.green,
          width: 3,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ),
      );
    }
  }

  LatLng _getDestinationCoordinates(String destination) {
    final Map<String, LatLng> destinations = {
      'UM Main Library': const LatLng(3.1235, 101.6545),
      'Student Center': const LatLng(3.1220, 101.6530),
      'Engineering Faculty': const LatLng(3.1240, 101.6555),
      'Sports Complex': const LatLng(3.1265, 101.6525),
      'Perpustakaan Utama UM': const LatLng(3.1235, 101.6545),
      'Student Affairs Division': const LatLng(3.1250, 101.6540),
      'Faculty of Engineering': const LatLng(3.1240, 101.6555),
      'UM Cafeteria Central': const LatLng(3.1225, 101.6535),
      'UM Sports Centre': const LatLng(3.1265, 101.6525),
      'Kolej Kediaman 4th College': const LatLng(3.1180, 101.6570),
    };
    return destinations[destination] ?? _universityMalayaCenter;
  }

  Future<Position> _getCurrentPosition() async {
    // Mock position for demo - in production, use real GPS
    final Random random = Random();
    return Position(
      latitude: _universityMalayaCenter.latitude + (random.nextDouble() - 0.5) * 0.01,
      longitude: _universityMalayaCenter.longitude + (random.nextDouble() - 0.5) * 0.01,
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

  void _simulatePartnerResponse() {
    // Stage 1: Finding partner (3 seconds)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          partnerFound = true;
          partnerStatus = '${widget.partner.name} found nearby!';
        });
      }
    });
    
    // Stage 2: Partner accepts (5 seconds)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          partnerAccepted = true;
          partnerStatus = '${widget.partner.name} accepted your request!';
          
          // Initialize partner location near user
          if (myCurrentPosition != null) {
            final Random random = Random();
            partnerCurrentPosition = Position(
              latitude: myCurrentPosition!.latitude + (random.nextDouble() - 0.5) * 0.002,
              longitude: myCurrentPosition!.longitude + (random.nextDouble() - 0.5) * 0.002,
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
        });
        _updateMapMarkers();
        _calculateDistance();
      }
    });
    
    // Stage 3: Partner on the way (7 seconds)
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() {
          partnerOnTheWay = true;
          partnerStatus = '${widget.partner.name} is walking to meet you';
        });
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Focus on user's location when map is ready
    if (myCurrentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(myCurrentPosition!.latitude, myCurrentPosition!.longitude),
          16.0,
        ),
      );
    }
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
          child: Column(
            children: [
              // Title Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Finding Partner',
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
              
              // Map Section
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
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
                      initialCameraPosition: const CameraPosition(
                        target: _universityMalayaCenter,
                        zoom: 16.0,
                      ),
                      markers: markers,
                      polylines: polylines,
                      myLocationEnabled: false, // We handle location markers manually
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      buildingsEnabled: true,
                      indoorViewEnabled: false,
                      trafficEnabled: false,
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
                          "featureType": "road",
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#38414e"
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
                        }
                      ]
                      ''',
                    ),
                  ),
                ),
              ),
              
              // Status Section
              Expanded(
                flex: 2,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(12), // Reduced from 16
                    child: SingleChildScrollView( // Add scroll view to prevent overflow
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Add this
                        children: [
                          // Partner Status Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16), // Reduced from 20
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Add this
                              children: [
                                // Partner Avatar with pulse animation
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: partnerFound ? 1.0 : _pulseAnimation.value,
                                      child: Container(
                                        width: 70, // Reduced from 80
                                        height: 70, // Reduced from 80
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: partnerAccepted 
                                              ? [Colors.green, Colors.lightGreen]
                                              : [Colors.deepPurple, Colors.purpleAccent],
                                          ),
                                          borderRadius: BorderRadius.circular(35), // Adjusted
                                          boxShadow: [
                                            BoxShadow(
                                              color: (partnerAccepted ? Colors.green : Colors.deepPurple).withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: partnerFound ? 0 : 5,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: partnerAccepted 
                                            ? const Icon(Icons.check_circle, size: 35, color: Colors.white) // Reduced from 40
                                            : Text(
                                                widget.partner.profilePicture ?? widget.partner.name[0],
                                                style: const TextStyle(
                                                  fontSize: 26, // Reduced from 30
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 12), // Reduced from 16
                                
                                // Status Text
                                Text(
                                  partnerStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16, // Reduced from 18
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 6), // Reduced from 8
                                
                                // Partner Info
                                if (partnerFound) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.partner.name,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14, // Reduced from 16
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6), // Reduced from 8
                                      const Icon(Icons.star, color: Colors.amber, size: 14), // Reduced from 16
                                      Text(
                                        ' ${widget.partner.rating}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12, // Reduced from 14
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                
                                // Distance and ETA (when partner is coming)
                                if (partnerAccepted && distanceToPartner > 0) ...[
                                  const SizedBox(height: 12), // Reduced from 16
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.directions_walk, color: Colors.green, size: 14), // Reduced from 16
                                        const SizedBox(width: 6), // Reduced from 8
                                        Text(
                                          '${distanceToPartner.toInt()}m away',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12, // Reduced from 14
                                          ),
                                        ),
                                        const SizedBox(width: 12), // Reduced from 16
                                        const Icon(Icons.schedule, color: Colors.green, size: 14), // Reduced from 16
                                        const SizedBox(width: 3), // Reduced from 4
                                        Text(
                                          '${estimatedArrivalMinutes}min',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12, // Reduced from 14
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12), // Reduced from 16
                          
                          // Action Buttons
                          if (partnerAccepted) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _callPartner(),
                                    icon: const Icon(Icons.phone, color: Colors.white, size: 16), // Reduced size
                                    label: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 12)), // Reduced font
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 12
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8), // Reduced from 12
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _startWalk(),
                                    icon: const Icon(Icons.directions_walk, color: Colors.white, size: 16), // Reduced size
                                    label: const Text('Start Walk', style: TextStyle(color: Colors.white, fontSize: 12)), // Reduced font
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 12
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 12
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel Request',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14, // Reduced from default
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          // Additional Info
                          const SizedBox(height: 8), // Reduced from 12
                          Text(
                            'Destination: ${widget.destination}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12, // Reduced from 14
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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

  void _callPartner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.partner.name}...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startWalk() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWalkScreen(partner: widget.partner),
      ),
    );
  }
}