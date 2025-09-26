import 'dart:async';
import 'dart:math' as math; // Ensures proper scoping for math functions
import 'dart:ui';
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
  Timer? _uiUpdateTimer;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final AnimationController _cardController;
  late final AnimationController _rippleController;
  
  // Animations
  late final Animation<double> _pulseAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _cardAnimation;
  late final Animation<double> _rippleAnimation;
  
  // Map data
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = <Polyline>{};
  final Set<Circle> _circles = <Circle>{};
  
  // Location data
  Position? _myPosition;
  Position? _partnerPosition;
  
  // State variables
  PartnerStatus _partnerStatus = PartnerStatus.searching;
  int _estimatedArrival = 0;
  double _distanceToPartner = 0.0;
  bool _isMapReady = false;
  int _searchingDuration = 0;
  String _currentStatusMessage = '';
  
  // Constants
  static const LatLng _universityCenter = LatLng(3.1225, 101.6532);
  static const double _walkingSpeedMs = 1.2;
  static const int _maxEstimatedMinutes = 30;
  static const double _cameraZoom = 16.0;
  static const double _partnerApproachRadius = 50.0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocation();
    _startLocationTracking();
    _startUIUpdates();
    _simulatePartnerResponse();
    _currentStatusMessage = _partnerStatus.message;
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _cardController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  // Enhanced animation setup
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

    _rippleController = AnimationController(
      duration: const Duration(seconds: 3),
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

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
    _slideController.forward();
  }

  // Enhanced location initialization with better error handling
  Future<void> _initializeLocation() async {
    try {
      final position = await _getCurrentPosition();
      if (mounted) {
        setState(() => _myPosition = position);
        _updateMapMarkers();
        _centerMapOnLocation();
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() => _myPosition = _createFallbackPosition());
        _updateMapMarkers();
        _showLocationError();
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
      const Duration(seconds: 2),
      (_) => _updateLocations(),
    );
  }

  void _startUIUpdates() {
    _uiUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateUI(),
    );
  }

  void _updateUI() {
    if (!mounted) return;
    
    setState(() {
      _searchingDuration++;
      if (_partnerStatus == PartnerStatus.searching) {
        _currentStatusMessage = _getSearchingMessage();
      }
    });
  }

  String _getSearchingMessage() {
    if (_searchingDuration < 5) {
      return 'Looking for your walking partner...';
    } else if (_searchingDuration < 10) {
      return 'Checking availability of your partner...';
    } else if (_searchingDuration < 15) {
      return 'Finding...';
    } else {
      return 'Almost found your partner...';
    }
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
    
    final random = math.Random();
    const variance = 0.0001;
    final approachRate = _partnerStatus == PartnerStatus.approaching ? 0.25 : 0.15;
    
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
        speed: random.nextDouble() * 2.0 + 1.0, // Random walking speed
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

    // Check if partner is very close
    if (distance <= _partnerApproachRadius && _partnerStatus != PartnerStatus.arrived) {
      setState(() => _partnerStatus = PartnerStatus.arrived);
    }
  }

  void _updateMapMarkers() {
    if (!_isMapReady) return;
    
    _markers.clear();
    _circles.clear();
    
    // My location marker with ripple effect
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

      // Add ripple effect around user location
      _circles.add(Circle(
        circleId: const CircleId('user_ripple'),
        center: LatLng(my.latitude, my.longitude),
        radius: 50 + (_rippleAnimation.value * 100),
        fillColor: Colors.green.withOpacity(0.1 * (1 - _rippleAnimation.value)),
        strokeColor: Colors.green.withOpacity(0.3 * (1 - _rippleAnimation.value)),
        strokeWidth: 2,
      ));
    }
    
    // Partner marker with status-based styling
    final partner = _partnerPosition;
    if (partner != null && _partnerStatus.isActive) {
      final markerColor = _partnerStatus == PartnerStatus.approaching 
        ? BitmapDescriptor.hueOrange
        : BitmapDescriptor.hueBlue;
        
      _markers.add(Marker(
        markerId: const MarkerId('partner'), // Fixed missing parenthesis
        position: LatLng(partner.latitude, partner.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: '${widget.partner.name} ${_getPartnerStatusEmoji()}',
          snippet: 'Walking Partner • ${_distanceToPartner.toInt()}m away',
        ),
      ));
      
      // Add circle around partner showing approach radius
      _circles.add(Circle(
        circleId: const CircleId('partner_radius'),
        center: LatLng(partner.latitude, partner.longitude),
        radius: _partnerApproachRadius,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 1,
      ));
      
      _drawRoute();
    }
    
    // Destination marker with enhanced styling
    final destination = _getDestinationCoordinates(widget.destination);
    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Destination 🎯',
        snippet: widget.destination,
      ),
    ));

    if (mounted) setState(() {});
  }

  String _getPartnerStatusEmoji() {
    switch (_partnerStatus) {
      case PartnerStatus.accepted:
        return '✅';
      case PartnerStatus.approaching:
        return '🚶‍♂️';
      case PartnerStatus.arrived:
        return '👋';
      default:
        return '';
    }
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
      color: _partnerStatus == PartnerStatus.approaching 
        ? Colors.orange 
        : Colors.deepPurple,
      width: 4,
      patterns: _partnerStatus == PartnerStatus.approaching 
        ? [PatternItem.dash(10), PatternItem.gap(5)]
        : [],
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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  void _simulatePartnerResponse() {
    // Partner found
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _partnerStatus = PartnerStatus.found;
        _currentStatusMessage = _partnerStatus.message;
      });
    });
    
    // Partner accepts
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _partnerStatus = PartnerStatus.accepted;
        _partnerPosition = _createPartnerPosition();
        _currentStatusMessage = _partnerStatus.message;
      });
      
      if (_cardController.status == AnimationStatus.dismissed) {
        _cardController.forward();
      }
      _updateMapMarkers();
      _calculateDistance();
    });
    
    // Partner approaching
    Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() {
        _partnerStatus = PartnerStatus.approaching;
        _currentStatusMessage = _partnerStatus.message;
      });
    });
  }

  Position? _createPartnerPosition() {
    final my = _myPosition;
    if (my == null) return null;
    
    final random = math.Random();
    const variance = 0.004;
    
    return Position(
      latitude: my.latitude + (random.nextDouble() - 0.5) * variance,
      longitude: my.longitude + (random.nextDouble() - 0.5) * variance,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: random.nextDouble() * 2.0 + 1.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    _centerMapOnLocation();
    _updateMapMarkers();
  }

  void _centerMapOnLocation() {
    final position = _myPosition;
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        _cameraZoom,
      ));
    }
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to get precise location. Using approximate campus location.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced Google Map with improved styling
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _universityCenter,
              zoom: _cameraZoom,
            ),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            trafficEnabled: false,
            liteModeEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            minMaxZoomPreference: const MinMaxZoomPreference(12.0, 20.0),
            cameraTargetBounds: CameraTargetBounds(LatLngBounds(
              southwest: const LatLng(3.110, 101.640),
              northeast: const LatLng(3.135, 101.670),
            )),
          ),
          
          // Enhanced header with gradient backdrop
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 20,
              ),
              child: Row(
                children: [
                  _buildBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waiting for Partner',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'To ${widget.destination}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildMapControls(),
                ],
              ),
            ),
          ),
          
          // Enhanced bottom sheet overlay
          _buildEnhancedBottomSheet(),
          
          // Enhanced safety button with notification dot
          if (_partnerStatus.isActive) _buildEnhancedSafetyButton(),

          // Status indicator overlay
          if (_partnerStatus == PartnerStatus.searching) _buildSearchingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => _showExitConfirmation(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB16EFF), Color(0xFF6C3EFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB16EFF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        GestureDetector(
          onTap: _centerMapOnLocation,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.deepPurple,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _zoomToFitAll,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.zoom_out_map,
              color: Colors.deepPurple,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingOverlay() {
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentStatusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${_searchingDuration}s',
              style: TextStyle(
                color: Colors.deepPurple.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Finding Walking Partner',
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
          _currentStatusMessage,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'re finding the best walking partner for you based on your preferences',
          style: TextStyle(
            fontSize: 14,
            color: Colors.purpleAccent[100],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildSearchingProgress(),
        const SizedBox(height: 16),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildSearchingProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_searchingDuration * 6.67).clamp(0, 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_searchingDuration / 15).clamp(0.0, 1.0),
            backgroundColor: Colors.deepPurple.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade400),
          ),
        ],
      ),
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
            gradient: const LinearGradient(
              colors: [
                Color(0xFF23234A),
                Color(0xFF181828),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.deepPurple.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
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
    return Stack(
      children: [
        Container(
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
        ),
        // Status indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(),
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_partnerStatus) {
      case PartnerStatus.found:
        return Colors.green;
      case PartnerStatus.accepted:
        return Colors.blue;
      case PartnerStatus.approaching:
        return Colors.orange;
      case PartnerStatus.arrived:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_partnerStatus) {
      case PartnerStatus.found:
        return Icons.check;
      case PartnerStatus.accepted:
        return Icons.directions_walk;
      case PartnerStatus.approaching:
        return Icons.near_me;
      case PartnerStatus.arrived:
        return Icons.location_on;
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildPartnerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.partner.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
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
            Flexible(
              child: Container(
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        if (_partnerPosition?.speed != null && _partnerPosition!.speed > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(
                '${_partnerPosition!.speed.toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDistanceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _distanceToPartner < 1000 
            ? '${_distanceToPartner.toInt()}m'
            : '${(_distanceToPartner/1000).toStringAsFixed(1)}km',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          '$_estimatedArrival min',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        if (_partnerStatus == PartnerStatus.approaching)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Coming',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
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
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
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
          if (_partnerStatus == PartnerStatus.arrived)
            const Icon(
              Icons.celebration,
              color: Colors.amber,
              size: 20,
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
    final canStart = _partnerStatus == PartnerStatus.arrived || 
                    (_partnerStatus == PartnerStatus.approaching && _distanceToPartner < 100);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canStart ? _startWalk : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart ? Colors.deepPurple : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canStart ? 5 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canStart) const Icon(Icons.directions_walk, size: 20),
            if (canStart) const SizedBox(width: 8),
            Text(
              canStart 
                ? 'Start Walking Together'
                : 'Waiting for partner to arrive...',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showExitConfirmation(),
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

  Widget _buildEnhancedSafetyButton() {
    return Positioned(
      right: 16,
      bottom: 340,
      child: Stack(
        children: [
          FloatingActionButton(
            onPressed: _openSafetyCenter,
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
            elevation: 8,
            child: const Icon(Icons.shield_outlined),
          ),
          // Notification dot for active safety monitoring
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced action methods
  void _callPartner() {
    _showSnackBar('Calling ${widget.partner.name}...', Colors.green);
  }

  void _messagePartner() {
    _showSnackBar('Opening chat with ${widget.partner.name}...', Colors.blue);
  }

  void _openSafetyCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SafetyCenterSheet(),
    );
  }

  void _zoomToFitAll() {
    if (_mapController == null) return;
    
    final my = _myPosition;
    final partner = _partnerPosition;
    
    if (my != null && partner != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(my.latitude, partner.latitude) - 0.001,
          math.min(my.longitude, partner.longitude) - 0.001,
        ),
        northeast: LatLng(
          math.max(my.latitude, partner.latitude) + 0.001,
          math.max(my.longitude, partner.longitude) + 0.001,
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } else {
      _centerMapOnLocation();
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Cancel Walking Request?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this walking request? Your partner will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Waiting'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cancel Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startWalk() {
    showDialog(
      context: context,
      builder: (context) => StartWalkDialog(
        partner: widget.partner,
        destination: widget.destination,
        estimatedTime: _estimatedArrival,
        distance: _distanceToPartner,
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveWalkScreen(
                partner: widget.partner,
                selectedDestination: widget.destination, // Corrected parameter
                destinationCoordinates: null, // Pass null or appropriate LatLng
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, [Color? backgroundColor]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Enhanced support classes and constants
enum PartnerStatus {
  searching('Looking for your walking partner...'),
  found('Walking partner found!'),
  accepted('Partner accepted your request'),
  approaching('Partner is walking to you'),
  arrived('Partner has arrived! Ready to walk?');

  const PartnerStatus(this.message);
  final String message;

  bool get isActive => this != searching;
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

// Enhanced separate widgets for better organization
class SafetyCenterSheet extends StatelessWidget {
  const SafetyCenterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text(
                'Safety Center',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your safety is our priority. Access emergency features and safety tools here.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Emergency Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          const Text(
            'Safety Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildSafetyFeatureTile(
                  Icons.location_on,
                  'Live Location Sharing',
                  'Your location is being shared with emergency contacts',
                  Colors.green,
                ),
                _buildSafetyFeatureTile(
                  Icons.timer,
                  'Safety Timer',
                  'Automatic check-in every 10 minutes',
                  Colors.blue,
                ),
                _buildSafetyFeatureTile(
                  Icons.verified_user,
                  'Partner Verification',
                  'Walking with verified university student',
                  Colors.purple,
                ),
                _buildSafetyFeatureTile(
                  Icons.route,
                  'Route Monitoring',
                  'Your walking route is being tracked',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyFeatureTile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 20),
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
        content: const Text(
          'This will call emergency services (999). Do you want to proceed?',
        ),
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
  final int estimatedTime;
  final double distance;
  final VoidCallback onConfirm;

  const StartWalkDialog({
    super.key,
    required this.partner,
    required this.destination,
    required this.estimatedTime,
    required this.distance,
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
          Text('Start Walking Together'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ready to start walking with ${partner.name}?'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.green),
                    SizedBox(width: 6),
                    Text('From: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Your current location'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 18, color: Colors.red),
                    const SizedBox(width: 6),
                    const Text('To: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Flexible(child: Text(destination)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    const Text('ETA: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('$estimatedTime min walk'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 18, color: Colors.orange),
                    const SizedBox(width: 6),
                    const Text('Distance: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(distance < 1000 
                      ? '${distance.toInt()}m' 
                      : '${(distance/1000).toStringAsFixed(1)}km'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safety features are active during your walk',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Start Walking'),
        ),
      ],
    );
  }
}