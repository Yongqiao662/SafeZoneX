import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sos_active_screen.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import '../services/websocket_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startEntryAnimation();
    // Enhanced location service removed for better performance
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with better spacing
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 24),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            // First row of actions
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.chat_bubble_rounded,
                    title: 'Connect',
                    subtitle: 'Live chat with safety advisors',
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
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.location_on_rounded,
                    title: 'Safe Zones',
                    subtitle: 'Find nearby safe spots',
                    color: const Color(0xFFE17055),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Second row of actions
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.phone_rounded,
                    title: 'Emergency Call',
                    subtitle: 'Instant dial 999',
                    color: const Color(0xFFE84393),
                    isEmergency: true,
                    onTap: () => _callEmergency(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.shield_rounded,
                    title: 'Check-In',
                    subtitle: 'Update safety status',
                    color: const Color(0xFF00B894),
                    onTap: () => _showSafeStatusDialog(),
                  ),
                ),
              ],
            ),
          ],
        ),
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
  bool isEmergency = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.03),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Subtitle
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  void _showSafeStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Safe Status Check-In',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Let your contacts know you\'re safe. This will send your location and status to your emergency contacts.',
          style: TextStyle(color: Colors.white70),
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
                  content: Text('Safe status sent to emergency contacts'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
            ),
            child: const Text(
              'Send Safe Status',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}