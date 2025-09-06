import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SOSActiveScreen extends StatefulWidget {
  @override
  _SOSActiveScreenState createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends State<SOSActiveScreen>
    with TickerProviderStateMixin {
  int countdown = 30;
  Timer? timer;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late AnimationController _bounceController;
  
  bool _isConnected = false;
  String _status = 'Connecting...';
  int _alertsSent = 0;
  List<Map<String, dynamic>> _statusMessages = [
    {'text': 'Emergency contacts notified', 'completed': false},
    {'text': 'Location shared with security', 'completed': false},
    {'text': 'Help is on the way', 'completed': false},
    {'text': 'Stay calm and safe', 'completed': false},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _rippleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Start countdown timer
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          countdown = 30; // Reset countdown
        }
      });
    });
    
    // Simulate connection and status updates
    _simulateConnection();
    
    // Add haptic feedback
    HapticFeedback.heavyImpact();
    
    // Trigger entrance animation
    _bounceController.forward();
  }

  void _simulateConnection() {
    Timer(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _status = 'Connected to Emergency Response';
        });
        HapticFeedback.selectionClick();
      }
    });
    
    // Add status messages progressively
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted && _alertsSent < _statusMessages.length) {
        setState(() {
          _statusMessages[_alertsSent]['completed'] = true;
          _alertsSent++;
        });
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                if (await _showCancelDialog()) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Emergency Alert Active',
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
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // Emergency status indicator
              },
              icon: const Icon(Icons.warning, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showCancelDialog();
      },
      child: Scaffold(
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
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                
                // Enhanced SOS Button with ripple effects
                AnimatedBuilder(
                  animation: Listenable.merge([_bounceController, _rippleController, _pulseController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_bounceController.value * 0.1),
                      child: Container(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple effects
                            ...List.generate(3, (index) {
                              final delay = index * 0.3;
                              final animationValue = (_rippleController.value - delay).clamp(0.0, 1.0);
                              return Container(
                                width: 220 * animationValue,
                                height: 220 * animationValue,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3 * (1 - animationValue)),
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                            
                            // Main SOS button
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.red[300]!,
                                    Colors.red[500]!,
                                    Colors.red[700]!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 25 + (15 * _pulseController.value),
                                    spreadRadius: 8 + (8 * _pulseController.value),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.medical_services,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 24),
                
                // Connection Status
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? Color(0xFF4CAF50) : Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isConnected ? Color(0xFF4CAF50) : Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Main title
                Text(
                  'Emergency Response Activated',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 32),
                
                // Countdown Timer Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: (30 - countdown) / 30,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation(Colors.red[500]),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${countdown}s',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Next location update in',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Status Updates Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Updates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      ...List.generate(
                        _statusMessages.length,
                        (index) => _buildStatusItem(
                          _statusMessages[index]['text'],
                          _statusMessages[index]['completed'],
                          index < _alertsSent,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Action Buttons
                _buildModernActionButton(
                  'Call Emergency Services',
                  Icons.phone,
                  Color(0xFFE53E3E),
                  () {
                    HapticFeedback.mediumImpact();
                    _makeEmergencyCall();
                  },
                ),
                
                SizedBox(height: 12),
                
                _buildModernActionButton(
                  'Turn On Camera',
                  Icons.camera_alt,
                  Color(0xFF3182CE),
                  () {
                    HapticFeedback.lightImpact();
                    _turnOnCameraAndMic();
                  },
                ),
                
                SizedBox(height: 12),
                
                _buildModernActionButton(
                  'Share Location',
                  Icons.my_location,
                  Color(0xFF38A169),
                  () {
                    HapticFeedback.lightImpact();
                    _shareLocation();
                  },
                ),
                
                SizedBox(height: 24),
                
                // Cancel Button
                Container(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      if (await _showCancelDialog()) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Cancel Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 32),
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

  Widget _buildStatusItem(String text, bool completed, bool visible) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.3,
      duration: Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: completed ? Color(0xFF4CAF50) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: completed 
                ? Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: completed ? Colors.grey[800] : Colors.grey[600],
                  fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<bool> _showCancelDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cancel Emergency Alert?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey[800],
            ),
          ),
          content: Text(
            'Are you sure you want to cancel the emergency alert? This will stop all emergency responses.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Active',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Cancel Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _makeEmergencyCall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
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
            SizedBox(height: 20),
            Icon(
              Icons.phone_in_talk,
              size: 48,
              color: Color(0xFFE53E3E),
            ),
            SizedBox(height: 16),
            Text(
              'Calling Emergency Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Connecting you to emergency services...',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[800],
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _turnOnCameraAndMic() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF3182CE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam,
                size: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Camera & Microphone Active',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Live feed is being shared with emergency responders',
              style: TextStyle(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.videocam_off, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Camera turned off'),
                            ],
                          ),
                          backgroundColor: Colors.red[600],
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.all(16),
                        ),
                      );
                    },
                    icon: Icon(Icons.videocam_off, size: 18),
                    label: Text('Turn Off'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Keep Active'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Location shared with emergency contacts'),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}