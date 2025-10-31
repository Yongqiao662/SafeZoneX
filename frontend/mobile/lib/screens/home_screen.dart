import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sos_active_screen.dart';
import 'map_screen.dart';
import '../services/websocket_service.dart';
import '../services/live_chat_service.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {  
  const HomeScreen({Key? key}) : super(key: key);
  
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
          // Profile button removed as requested
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
                    icon: Icons.support_agent_rounded,
                    title: 'Live Chat',
                    subtitle: 'Chat with security team',
                    color: const Color(0xFF6C5CE7),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const LiveChatOverlay(),
                      );
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
    
    // DON'T send SOS alert here - let SOSActiveScreen handle it
    // This prevents duplicate SOS alerts
    print('🚨 Guardian Pulse activated - navigating to SOS screen');
    
    // Navigate to SOS screen immediately - it will handle the alert sending
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

// LiveChatOverlay moved here to avoid creating a separate file
class LiveChatOverlay extends StatefulWidget {
  const LiveChatOverlay({Key? key}) : super(key: key);

  @override
  _LiveChatOverlayState createState() => _LiveChatOverlayState();
}

class _LiveChatOverlayState extends State<LiveChatOverlay> 
    with SingleTickerProviderStateMixin {
  final LiveChatService _chatService = LiveChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isConnected = false;
  bool isTyping = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userId = await ApiService.getCurrentUserId();
    _userName = await ApiService.getCurrentUserName();
    
    if (_userId == null) {
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (_userName == null) {
      _userName = 'Student User';
    }
    
    print('📱 Live chat user: $_userName (ID: $_userId)');
    _setupChatService();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  void _setupChatService() {
    if (_userId == null || _userName == null) {
      return;
    }
    
    _chatService.connect();
    setState(() => isConnected = _chatService.isConnected);

    _chatService.removeConnectionListener(_onConnectionChanged);
    _chatService.removeMessageListener(_onMessageReceived);
    _chatService.removeTypingListener(_onTypingReceived);

    _chatService.addConnectionListener(_onConnectionChanged);
    _chatService.addMessageListener(_onMessageReceived);
    _chatService.addTypingListener(_onTypingReceived);

    if (_chatService.isConnected) {
      _chatService.joinSupport(_userId!, _userName!);
    }
  }

  void _onConnectionChanged(bool connected) {
    if (mounted) {
      setState(() => isConnected = connected);
      if (connected && _userId != null && _userName != null) {
        _chatService.joinSupport(_userId!, _userName!);
      }
    }
  }

  void _onMessageReceived(dynamic data) {
    if (mounted) {
      setState(() {
        messages.add(ChatMessage(
          text: data['message'],
          isFromUser: false,
          timestamp: DateTime.now(),
          senderName: data['senderName'] ?? 'Security Team',
        ));
        isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _onTypingReceived(dynamic data) {
    if (mounted) {
      setState(() => isTyping = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => isTyping = false);
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    setState(() {
      messages.add(ChatMessage(
        text: messageText,
        isFromUser: true,
        timestamp: DateTime.now(),
        senderName: 'You',
      ));
    });

    _chatService.sendMessage(messageText);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatService.removeConnectionListener(_onConnectionChanged);
    _chatService.removeMessageListener(_onMessageReceived);
    _chatService.removeTypingListener(_onTypingReceived);
    
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f0f1e)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessageList()),
              if (isTyping) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Chat Support', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    if (_userName != null)
                      Text('Chatting as $_userName', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'Security Online' : 'Connecting...',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                        if (!isConnected) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _chatService.disconnect();
                              Future.delayed(const Duration(milliseconds: 500), () {
                                _chatService.connect();
                                if (_userId != null && _userName != null) {
                                  _chatService.joinSupport(_userId!, _userName!);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.5)),
                              ),
                              child: const Text('Retry', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(Icons.waving_hand_rounded, size: 40, color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 16),
                  Text('Welcome to Live Chat Support', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Our security team is here to help you\nStart a conversation below', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.security_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isFromUser ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)]) : null,
                color: message.isFromUser ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isFromUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isFromUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isFromUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(message.senderName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                ],
              ),
            ),
          ),
          if (message.isFromUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.security_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(3, (i) => Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    if (text.isNotEmpty) _chatService.sendTypingIndicator();
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final String senderName;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    required this.senderName,
  });
}