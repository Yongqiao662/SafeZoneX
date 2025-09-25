import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
    super.key,
    required this.partner,
    required this.destination,
    required this.departureTime,
    required this.message,
  });

  @override
  State<PartnerWaitingScreen> createState() => _PartnerWaitingScreenState();
}

class _PartnerWaitingScreenState extends State<PartnerWaitingScreen> 
    with TickerProviderStateMixin {
  
  // Controllers and streams
  GoogleMapController? _mapController;
  Timer? _locationUpdateTimer;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final AnimationController _cardController;
  
  // Animations
  late final Animation<double> _pulseAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _cardAnimation;
  
  // Map data
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = <Polyline>{};
  
  // Location data
  Position? _myPosition;
  Position? _partnerPosition;
  
  // State variables
  PartnerStatus _partnerStatus = PartnerStatus.searching;
  int _estimatedArrival = 0;
  double _distanceToPartner = 0.0;
  
  // Constants
  static const LatLng _universityCenter = LatLng(3.1225, 101.6532);
  static const double _walkingSpeedMs = 1.2;
  static const int _maxEstimatedMinutes = 30;
  
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
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // Animation setup
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  // Location initialization
  Future<void> _initializeLocation() async {
    try {
      final position = await _getCurrentPosition();
      if (mounted) {
        setState(() => _myPosition = position);
        _updateMapMarkers();
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() => _myPosition = _createFallbackPosition());
        _updateMapMarkers();
      }
    }
  }

  Position _createFallbackPosition() {
    return Position(
      latitude: _universityCenter.latitude,
      longitude: _universityCenter.longitude,
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

  void _startLocationTracking() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _updateLocations(),
    );
  }

  Future<void> _updateLocations() async {
    if (!mounted) return;
    
    try {
      final newPosition = await _getCurrentPosition();
      setState(() => _myPosition = newPosition);
      
      if (_partnerStatus.isActive) {
        _updatePartnerLocation();
      }
      
      _updateMapMarkers();
      _calculateDistance();
    } catch (e) {
      debugPrint('Location update error: $e');
    }
  }

  void _updatePartnerLocation() {
    final partner = _partnerPosition;
    final my = _myPosition;
    if (partner == null || my == null) return;
    
    final random = Random();
    const variance = 0.0001;
    const approachRate = 0.15;
    
    final latOffset = (random.nextDouble() - 0.5) * variance;
    final lngOffset = (random.nextDouble() - 0.5) * variance;
    
    final directionLat = (my.latitude - partner.latitude) * approachRate;
    final directionLng = (my.longitude - partner.longitude) * approachRate;
    
    setState(() {
      _partnerPosition = Position(
        latitude: partner.latitude + directionLat + latOffset,
        longitude: partner.longitude + directionLng + lngOffset,
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

  void _calculateDistance() {
    final my = _myPosition;
    final partner = _partnerPosition;
    if (my == null || partner == null) return;
    
    final distance = Geolocator.distanceBetween(
      my.latitude,
      my.longitude,
      partner.latitude,
      partner.longitude,
    );
    
    setState(() {
      _distanceToPartner = distance;
      _estimatedArrival = (distance / _walkingSpeedMs / 60)
          .ceil()
          .clamp(1, _maxEstimatedMinutes);
    });
  }

  void _updateMapMarkers() {
    _markers.clear();
    
    // My location marker
    final my = _myPosition;
    if (my != null) {
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(my.latitude, my.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Pickup Point',
          snippet: 'You are here',
        ),
      ));
    }
    
    // Partner marker
    final partner = _partnerPosition;
    if (partner != null && _partnerStatus.isActive) {
      _markers.add(Marker(
        markerId: const MarkerId('partner'),
        position: LatLng(partner.latitude, partner.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: widget.partner.name,
          snippet: 'Walking Partner',
        ),
      ));
      
      _drawRoute();
    }
    
    // Destination marker
    final destination = _getDestinationCoordinates(widget.destination);
    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Destination',
        snippet: widget.destination,
      ),
    ));
  }

  void _drawRoute() {
    final my = _myPosition;
    final partner = _partnerPosition;
    if (my == null || partner == null) return;
    
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [
        LatLng(my.latitude, my.longitude),
        LatLng(partner.latitude, partner.longitude),
      ],
      color: Colors.deepPurple,
      width: 4,
    ));
  }

  LatLng _getDestinationCoordinates(String destination) {
    return DestinationMap.locations[destination] ?? _universityCenter;
  }

  Future<Position> _getCurrentPosition() async {
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
  }

  void _simulatePartnerResponse() {
    // Partner found
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _partnerStatus = PartnerStatus.found);
    });
    
    // Partner accepts
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _partnerStatus = PartnerStatus.accepted;
        _partnerPosition = _createPartnerPosition();
      });
      
      if (_cardController.status == AnimationStatus.dismissed) {
        _cardController.forward();
      }
      _updateMapMarkers();
      _calculateDistance();
    });
    
    // Partner approaching
    Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() => _partnerStatus = PartnerStatus.approaching);
    });
  }

  Position? _createPartnerPosition() {
    final my = _myPosition;
    if (my == null) return null;
    
    final random = Random();
    const variance = 0.004;
    
    return Position(
      latitude: my.latitude + (random.nextDouble() - 0.5) * variance,
      longitude: my.longitude + (random.nextDouble() - 0.5) * variance,
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final position = _myPosition;
    if (position != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        15.0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _universityCenter,
              zoom: 16.0,
            ),
            markers: _markers,
            polylines: _polylines,
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
          ),
          
          // Header overlay with no black bar behind
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB16EFF), Color(0xFF6C3EFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFB16EFF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Waiting for Partner',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 105, 17, 206),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Enhanced bottom sheet overlay with purple theme
          _buildEnhancedBottomSheet(),
          
          // Safety button when partner is active
          if (_partnerStatus.isActive) _buildSafetyButton(),
        ],
      ),
    );
  }

  // Enhanced bottom sheet with better functionality
  Widget _buildEnhancedBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF181828),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 20),
                if (_partnerStatus.isActive) 
                  _buildPartnerFoundContent()
                else 
                  _buildSearchingContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.deepPurple[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSearchingContent() {
    return Column(
      children: [
        // Only text for "Walking for Partner"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Walking for Partner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _partnerStatus.message,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'re finding the best walking partner for you',
          style: TextStyle(
            fontSize: 14,
            color: Colors.purpleAccent[100],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildPartnerFoundContent() {
    return Column(
      children: [
        _buildPartnerCard(),
        const SizedBox(height: 20),
        _buildStatusMessage(),
        const SizedBox(height: 20),
        _buildActionButtons(),
        const SizedBox(height: 12),
        _buildStartWalkButton(),
      ],
    );
  }

  Widget _buildPartnerCard() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) => Transform.scale(
        scale: _cardAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF23234A),
                Color(0xFF181828),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.deepPurple.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              _buildPartnerAvatar(),
              const SizedBox(width: 16),
              Expanded(child: _buildPartnerInfo()),
              if (_distanceToPartner > 0) _buildDistanceInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
        ),
        borderRadius: BorderRadius.all(Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: widget.partner.profilePicture != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.network(
                widget.partner.profilePicture!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      widget.partner.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                widget.partner.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildPartnerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.partner.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (widget.partner.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.verified,
                color: Colors.blue,
                size: 18,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              '${widget.partner.rating}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Text(
                widget.partner.department,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${_distanceToPartner.toInt()}m',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          '$_estimatedArrival min',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.purpleAccent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _partnerStatus.message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _callPartner,
            icon: const Icon(Icons.phone, size: 20, color: Colors.white),
            label: const Text('Call', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.deepPurple),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _messagePartner,
            icon: const Icon(Icons.message, size: 20, color: Colors.white),
            label: const Text('Message', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.deepPurple),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartWalkButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startWalk,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Start Walking Together',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF23234A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Cancel Request',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyButton() {
    return Positioned(
      right: 16,
      bottom: 320,
      child: FloatingActionButton(
        onPressed: _openSafetyCenter,
        backgroundColor: Colors.white,
        foregroundColor: Colors.red,
        elevation: 8,
        child: const Icon(Icons.shield_outlined),
      ),
    );
  }

  // Action methods
  void _callPartner() {
    _showSnackBar('Calling ${widget.partner.name}...');
  }

  void _messagePartner() {
    _showSnackBar('Opening chat with ${widget.partner.name}...');
  }

  void _openSafetyCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SafetyCenterSheet(),
    );
  }

  void _startWalk() {
    showDialog(
      context: context,
      builder: (context) => StartWalkDialog(
        partner: widget.partner,
        destination: widget.destination,
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveWalkScreen(partner: widget.partner),
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Support classes and constants
enum PartnerStatus {
  searching('Looking for your walking partner...'),
  found('Walking partner found!'),
  accepted('Partner is on the way'),
  approaching('Partner is walking to you');

  const PartnerStatus(this.message);
  final String message;

  bool get isActive => this == accepted || this == approaching;
}

class DestinationMap {
  static const Map<String, LatLng> locations = {
    'UM Main Library': LatLng(3.1235, 101.6545),
    'Student Center': LatLng(3.1220, 101.6530),
    'Engineering Faculty': LatLng(3.1240, 101.6555),
    'Sports Complex': LatLng(3.1265, 101.6525),
    'Perpustakaan Utama UM': LatLng(3.1235, 101.6545),
    'Student Affairs Division': LatLng(3.1250, 101.6540),
    'Faculty of Engineering': LatLng(3.1240, 101.6555),
    'UM Cafeteria Central': LatLng(3.1225, 101.6535),
    'UM Sports Centre': LatLng(3.1265, 101.6525),
    'Kolej Kediaman 4th College': LatLng(3.1180, 101.6570),
  };
}

// Separate widgets for better organization
class SafetyCenterSheet extends StatelessWidget {
  const SafetyCenterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.shield_outlined, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Safety Center',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Need help? Access emergency features here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _callEmergency(context);
                  },
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text('Call 999'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareLocation(context);
                  },
                  icon: const Icon(Icons.share_location),
                  label: const Text('Share Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _callEmergency(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Emergency Call'),
          ],
        ),
        content: const Text('This will call emergency services (999). Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling emergency services...'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Call Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _shareLocation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared with emergency contacts'),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class StartWalkDialog extends StatelessWidget {
  final UserProfile partner;
  final String destination;
  final VoidCallback onConfirm;

  const StartWalkDialog({
    super.key,
    required this.partner,
    required this.destination,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.directions_walk, color: Colors.deepPurple, size: 24),
          SizedBox(width: 8),
          Text('Start Walking'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ready to start walking with ${partner.name}?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text('From: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('Your current location'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    const Text('To: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(destination),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('ETA: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('15 min walk'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not Yet'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Start Walking'),
        ),
      ],
    );
  }
}