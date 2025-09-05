import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sos_active_screen.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import '../services/websocket_service.dart';
import '../services/enhanced_location_tracking_service.dart';
import '../widgets/enhanced_location_dashboard.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onChatTap;
  
  const HomeScreen({Key? key, this.onChatTap}) : super(key: key);
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _cardController;
  late AnimationController _sosController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardOpacityAnimation;
  late Animation<double> _sosScaleAnimation;
  
  bool _isGuardianPulseActive = false;
  
  // Services
  final WebSocketService _wsService = WebSocketService();
  final EnhancedLocationTrackingService _enhancedLocationService = EnhancedLocationTrackingService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeServices();
    _startEntryAnimation();
    _connectWebSocket();
  }
  
  void _connectWebSocket() async {
    try {
      await _wsService.connect();
      print('🔌 Connected to SafeZoneX server');
    } catch (e) {
      print('❌ Failed to connect to server: $e');
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _sosController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardOpacityAnimation = CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.3, 1.0),
    );
    
    _sosScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_sosController);

    // Start pulsing animation
    _pulseController.repeat(reverse: true);
  }

  /// Initialize enhanced location service
  Future<void> _initializeServices() async {
    try {
      // Initialize with your Google Maps API key
      await _enhancedLocationService.initialize(
        googleMapsApiKey: 'AIzaSyAhVXxYn4NttDrHLzRHy1glc8ukrmkissM', // Your actual API key
        backendApiUrl: 'ws://10.0.2.2:8080', // Your backend URL
      );

      // Set up callbacks for location updates
      _enhancedLocationService.onLocationUpdate = (position, address) {
        if (mounted) {
          setState(() {
            // Update UI with new location
          });
        }
      };

      _enhancedLocationService.onSafeZoneStatusChanged = (isInSafeZone) {
        if (mounted) {
          setState(() {
            // Update safe zone status in UI
          });
        }
      };

      _enhancedLocationService.onEmergencyTriggered = (emergencyData) {
        // Handle emergency alerts
        final location = emergencyData['location'] as Map<String, dynamic>;
        _wsService.sendSOSAlert(
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          userName: 'Current User',
          userPhone: '+1234567890',
          latitude: location['latitude'],
          longitude: location['longitude'],
          address: location['address'] ?? 'Unknown location',
          additionalInfo: 'Enhanced emergency tracking activated',
        );
      };

    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  void _startEntryAnimation() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _cardController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _sosController.dispose();
    _wsService.dispose();
    super.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildWelcomeSection(),
                        const SizedBox(height: 40),
                        _buildGuardianPulse(),
                        const SizedBox(height: 50),
                        _buildQuickActions(),
                        const SizedBox(height: 30),
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        // Enhanced Location Tracking Dashboard
                        const EnhancedLocationDashboard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
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
              Icons.security,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'SafeZoneX',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              icon: const Icon(Icons.person_outline, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your Safety Hub is Active',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'All Systems Online',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuardianPulse() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: _sosScaleAnimation,
          child: Column(
            children: [
              GestureDetector(
                onTapDown: (_) {
                  _sosController.forward();
                  HapticFeedback.mediumImpact();
                },
                onTapUp: (_) {
                  _sosController.reverse();
                },
                onTapCancel: () {
                  _sosController.reverse();
                },
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  _activateGuardianPulse();
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _isGuardianPulseActive 
                          ? Colors.red.withOpacity(0.8)
                          : Colors.red.withOpacity(0.7),
                        _isGuardianPulseActive
                          ? Colors.red.shade800
                          : Colors.red.shade900,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isGuardianPulseActive ? Colors.red : const Color.fromARGB(255, 231, 0, 39))
                            .withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: _pulseAnimation.value * 10,
                      ),
                      BoxShadow(
                        color: (_isGuardianPulseActive ? Colors.red : const Color.fromARGB(255, 231, 0, 39))
                            .withOpacity(0.2),
                        blurRadius: 60,
                        spreadRadius: _pulseAnimation.value * 20,
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isGuardianPulseActive 
                            ? Icons.warning_rounded
                            : Icons.notifications_active_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isGuardianPulseActive ? 'ACTIVE' : 'SOS',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          _isGuardianPulseActive ? 'EMERGENCY' : 'Alert',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hold to activate emergency alert',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardOpacityAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.chat_bubble_rounded,
                    title: 'Connect',
                    subtitle: 'Live Chat Support',
                    color: const Color(0xFF6C5CE7),
                    onTap: () {
                      if (widget.onChatTap != null) {
                        widget.onChatTap!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatScreen()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.directions_walk_rounded,
                    title: 'Escort',
                    subtitle: 'Request Safe Walk',
                    color: const Color(0xFF00CEC9),
                    onTap: () => _requestEscort(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.location_on_rounded,
                    title: 'Campus Safe Zones',
                    subtitle: 'Nearby Safe Spots',
                    color: const Color(0xFFE17055),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.phone_rounded,
                    title: 'Emergency',
                    subtitle: 'Quick Dial 999',
                    color: const Color(0xFFE84393),
                    onTap: () => _callEmergency(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardOpacityAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Safety Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusItem('Location Tracking', true),
              _buildStatusItem('Emergency Contacts', true),
              _buildStatusItem('Network Connection', true),
              _buildStatusItem('GPS Signal', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _activateGuardianPulse() async {
    setState(() => _isGuardianPulseActive = true);
    HapticFeedback.heavyImpact();
    
    // Send SOS alert with real location via WebSocket
    try {
      await _wsService.sendSOSAlertWithRealLocation(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        userName: 'Current User', // Replace with actual user name
        userPhone: '+1234567890', // Replace with actual user phone
        alertType: 'Emergency SOS - Guardian Pulse Activated',
        additionalInfo: 'Emergency SOS button pressed with real-time location tracking',
      );
      
      print('🚨 SOS Alert sent with real GPS location to monitoring dashboard!');
    } catch (e) {
      print('❌ Failed to send SOS alert: $e');
      // Fallback to basic alert if location fails
      _wsService.sendSOSAlert(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        userName: 'Current User',
        userPhone: '+1234567890',
        latitude: 0.0, // Fallback coordinates
        longitude: 0.0,
        address: 'Location unavailable',
        alertType: 'Emergency SOS - Location Failed',
        additionalInfo: 'SOS button pressed - Location service unavailable: $e',
      );
    }
    
    // Navigate to SOS screen after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SOSActiveScreen()),
      ).then((_) {
        // Reset state when returning from SOS screen
        setState(() => _isGuardianPulseActive = false);
      });
    });
  }

  void _requestEscort() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Escort request sent successfully'),
        backgroundColor: const Color(0xFF00CEC9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _callEmergency() {
    // Implement emergency call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connecting to emergency services...'),
        backgroundColor: const Color(0xFFE84393),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}