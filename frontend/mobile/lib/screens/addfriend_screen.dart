import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SOSAlert {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final double latitude;
  final double longitude;
  final String address;
  final String timestamp;
  final String message;
  final String urgency;
  final String status;
  final List<dynamic> acknowledgedBy;

  SOSAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.message,
    required this.urgency,
    this.status = 'active',
    this.acknowledgedBy = const [],
  });

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      userPhoto: json['userPhoto'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? 'Unknown location',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      message: json['message'] ?? 'Emergency alert',
      urgency: json['urgency'] ?? 'high',
      status: json['status'] ?? 'active',
      acknowledgedBy: json['acknowledgedBy'] ?? [],
    );
  }
}

class Friend {
  final String id;
  final String name;
  final String username;
  final String email;
  final bool isOnline;
  final String lastSeen;
  final String profileColor;
  final String location;
  final String locationUpdated;
  bool inSOS; // NEW: Track if friend is in SOS mode

  Friend({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.isOnline,
    required this.lastSeen,
    required this.profileColor,
    required this.location,
    required this.locationUpdated,
    this.inSOS = false, // NEW
  });
}

class ChatMessage {
  final String id;
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String status; // sent, delivered, read

  ChatMessage({
    required this.id,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.status = 'delivered',
  });
}

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _searchTextController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _searchAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchAnimation;
  
  List<Friend> allFriends = [
    Friend(
      id: '1',
      name: 'Sarah Wilson',
      username: 'sarah_w',
      email: 'sarah.wilson@university.edu',
      isOnline: true,
      lastSeen: 'Online',
      profileColor: 'purple',
      location: 'Library - Level 3',
      locationUpdated: '2 min ago',
    ),
    Friend(
      id: '2',
      name: 'Mike Chen',
      username: 'mike_chen',
      email: 'mike.chen@university.edu',
      isOnline: false,
      lastSeen: '2 minutes ago',
      profileColor: 'blue',
      location: 'Engineering Building',
      locationUpdated: '15 min ago',
    ),
    Friend(
      id: '3',
      name: 'Emma Davis',
      username: 'emma_d',
      email: 'emma.davis@university.edu',
      isOnline: true,
      lastSeen: 'Online',
      profileColor: 'green',
      location: 'Student Center',
      locationUpdated: '1 min ago',
    ),
    Friend(
      id: '4',
      name: 'Alex Thompson',
      username: 'alex_t',
      email: 'alex.thompson@university.edu',
      isOnline: false,
      lastSeen: '1 hour ago',
      profileColor: 'orange',
      location: 'Dormitory Block A',
      locationUpdated: '1 hour ago',
    ),
  ];

  List<Friend> searchResults = [];
  List<Friend> filteredFriends = [];
  String searchQuery = '';
  bool isSearching = false;
  
  // WebSocket for real-time SOS alerts
  IO.Socket? _socket;
  List<SOSAlert> _activeSOSAlerts = [];
  bool _isConnectedToBackend = false;
  Timer? _connectionRetryTimer;

  // Mock chat data for different friends
  Map<String, List<ChatMessage>> chatHistory = {
    '1': [
      ChatMessage(
        id: '1',
        message: 'Hey! Are you free to walk to the dining hall together?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
      ChatMessage(
        id: '2',
        message: 'Sure! I\'m at the library right now. Give me 5 minutes?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 28)),
      ),
      ChatMessage(
        id: '3',
        message: 'Perfect! I\'ll wait for you at the main entrance',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 25)),
      ),
      ChatMessage(
        id: '4',
        message: 'On my way! Thanks for walking with me 😊',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 20)),
      ),
    ],
    '2': [
      ChatMessage(
        id: '1',
        message: 'Did you finish the assignment for Prof. Martinez?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
      ChatMessage(
        id: '2',
        message: 'Yes! Want to study together for the exam next week?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 45)),
      ),
      ChatMessage(
        id: '3',
        message: 'Definitely! Library tomorrow at 3 PM?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 30)),
      ),
    ],
    '3': [
      ChatMessage(
        id: '1',
        message: 'Emergency! Lost my keys somewhere on campus',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 45)),
      ),
      ChatMessage(
        id: '2',
        message: 'Oh no! Did you check the student center lost & found?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 40)),
      ),
      ChatMessage(
        id: '3',
        message: 'Found them! They were in my backpack pocket all along 🤦‍♀️',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 35)),
      ),
      ChatMessage(
        id: '4',
        message: 'Haha classic! Glad you found them. Want to grab coffee?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
    ],
    '4': [
      ChatMessage(
        id: '1',
        message: 'Hey! Are you planning to attend the campus safety workshop tomorrow?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
      ),
      ChatMessage(
        id: '2',
        message: 'I completely forgot about it! What time was it again?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
      ),
      ChatMessage(
        id: '3',
        message: '2 PM at the main auditorium. It\'s about the new SafeZoneX app!',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    filteredFriends = allFriends;
    _initAnimations();
    _fadeController.value = 1.0;
    _slideController.value = 1.0;
    _searchAnimationController.value = 1.0;
    _searchTextController.addListener(_onSearchChanged);
    
    // Connect to backend for real-time SOS alerts
    _connectToBackendForSOSAlerts();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchTextController.text.toLowerCase();
      isSearching = searchQuery.isNotEmpty;
      
      if (searchQuery.isEmpty) {
        filteredFriends = allFriends;
        searchResults = [];
      } else {
        searchResults = _simulateUserSearch(searchQuery);
        filteredFriends = allFriends.where((friend) =>
          friend.name.toLowerCase().contains(searchQuery) ||
          friend.username.toLowerCase().contains(searchQuery) ||
          friend.email.toLowerCase().contains(searchQuery)
        ).toList();
      }
    });
  }

  List<Friend> _simulateUserSearch(String query) {
    List<Friend> allUsers = [
      ...allFriends,
      Friend(
        id: '5',
        name: 'Jessica Park',
        username: 'jessica_park',
        email: 'jessica.park@university.edu',
        isOnline: false,
        lastSeen: 'Not added',
        profileColor: 'pink',
        location: 'Unknown',
        locationUpdated: 'Never',
      ),
      Friend(
        id: '6',
        name: 'David Kim',
        username: 'david_kim',
        email: 'david.kim@university.edu',
        isOnline: true,
        lastSeen: 'Not added',
        profileColor: 'cyan',
        location: 'Unknown',
        locationUpdated: 'Never',
      ),
    ];

    return allUsers.where((user) =>
      !allFriends.any((friend) => friend.id == user.id) &&
      (user.name.toLowerCase().contains(query) ||
       user.username.toLowerCase().contains(query) ||
       user.email.toLowerCase().contains(query))
    ).toList();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchAnimationController.dispose();
    _searchTextController.dispose();
    
    // Clean up WebSocket connection
    _connectionRetryTimer?.cancel();
    if (_socket != null && _socket!.connected) {
      _socket?.disconnect();
      _socket?.dispose();
    }
    
    super.dispose();
  }

  // Connect to backend for real-time SOS alerts
  void _connectToBackendForSOSAlerts() async {
    try {
      // Initialize socket connection (use 10.0.2.2 for Android emulator)
      _socket = IO.io('http://10.0.2.2:8080', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket?.connect();

      _socket?.onConnect((_) {
        print('✅ Connected to backend for SOS alerts');
        if (mounted) {
          setState(() {
            _isConnectedToBackend = true;
          });
        }
      });

      _socket?.onDisconnect((_) {
        print('❌ Disconnected from backend');
        if (mounted) {
          setState(() {
            _isConnectedToBackend = false;
          });
        }
        
        // Auto-reconnect after 5 seconds
        _connectionRetryTimer?.cancel();
        _connectionRetryTimer = Timer(Duration(seconds: 5), () {
          if (mounted && (_socket == null || !_socket!.connected)) {
            print('🔄 Attempting to reconnect...');
            _socket?.connect();
          }
        });
      });

      // Listen for friend SOS alerts
      _socket?.on('friend_sos_alert', (data) {
        print('🆘 Received SOS alert: $data');
        _handleIncomingSOSAlert(data);
      });

      // Listen for location updates
      _socket?.on('friend_location_update', (data) {
        print('📍 Received location update: $data');
        _handleLocationUpdate(data);
      });

      // Listen for SOS ended
      _socket?.on('friend_sos_ended', (data) {
        print('✅ SOS ended: $data');
        _handleSOSEnded(data);
      });

    } catch (e) {
      print('❌ Error connecting to backend: $e');
    }
  }

  void _handleIncomingSOSAlert(dynamic data) {
    try {
      final sosAlert = SOSAlert.fromJson(Map<String, dynamic>.from(data));
      
      if (mounted) {
        setState(() {
          // Add to active alerts list
          _activeSOSAlerts.add(sosAlert);
          
          // Mark friend as in SOS mode
          final friendIndex = allFriends.indexWhere(
            (f) => f.name.toLowerCase().contains(sosAlert.userName.toLowerCase())
          );
          if (friendIndex != -1) {
            allFriends[friendIndex].inSOS = true;
          }
        });
        
        // Show notification dialog
        _showSOSNotificationDialog(sosAlert);
        
        // Send vibration/haptic feedback
        HapticFeedback.vibrate();
      }
    } catch (e) {
      print('Error parsing SOS alert: $e');
    }
  }

  void _handleLocationUpdate(dynamic data) {
    try {
      final userId = data['userId'];
      final lat = (data['latitude'] ?? 0.0).toDouble();
      final lng = (data['longitude'] ?? 0.0).toDouble();
      final address = data['address'] ?? 'Unknown';
      
      // Update the location in active SOS alerts
      if (mounted) {
        setState(() {
          for (var alert in _activeSOSAlerts) {
            if (alert.userId == userId) {
              // In a real app, you'd create a new SOSAlert with updated location
              // For now, just log it
              print('📍 Updated location for ${alert.userName}: $address');
            }
          }
        });
      }
    } catch (e) {
      print('Error handling location update: $e');
    }
  }

  void _handleSOSEnded(dynamic data) {
    try {
      final userId = data['userId'];
      
      if (mounted) {
        setState(() {
          // Remove from active alerts
          _activeSOSAlerts.removeWhere((alert) => alert.userId == userId);
          
          // Mark friend as no longer in SOS
          for (var friend in allFriends) {
            if (friend.inSOS) {
              friend.inSOS = false;
            }
          }
        });
        
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend is no longer in emergency mode'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error handling SOS ended: $e');
    }
  }

  void _showSOSNotificationDialog(SOSAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning, color: Colors.red, size: 30),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🆘 Emergency Alert',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${alert.userName} needs help!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.message,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.address,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Just now',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Dismiss',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Acknowledge the SOS
                _acknowledgeSOSAlert(alert);
                Navigator.pop(context);
                // Navigate to map view showing friend's location
                _showFriendLocationOnMap(alert);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'View Location & Help',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _acknowledgeSOSAlert(SOSAlert alert) {
    if (_socket != null && _socket!.connected) {
      _socket?.emit('sos_acknowledge', {
        'alertId': alert.id,
        'friendId': 'current_user_id', // Replace with actual user ID
        'friendName': 'My Name', // Replace with actual user name
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      print('✅ Acknowledged SOS alert');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${alert.userName} has been notified you\'re aware'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFriendLocationOnMap(SOSAlert alert) {
    // Show dialog with map and friend location
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '${alert.userName}\'s Location',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 80, color: Colors.white38),
                        SizedBox(height: 12),
                        Text(
                          'Map View',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lat: ${alert.latitude.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          'Lng: ${alert.longitude.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.address,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // In real app, open Google Maps navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening navigation...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.directions),
              label: Text('Navigate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
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
                // SOS Alert Banner
                if (_activeSOSAlerts.isNotEmpty)
                  _buildSOSBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildSearchSection(),
                        const SizedBox(height: 30),
                        if (isSearching && searchResults.isNotEmpty)
                          _buildSearchResults(),
                        if (isSearching && searchResults.isEmpty && searchQuery.isNotEmpty)
                          _buildNoResults(),
                        if (!isSearching || filteredFriends.isNotEmpty)
                          _buildFriendsList(),
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
              Icons.people,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Friends',
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
              onPressed: () => _showAddFriendDialog(),
              icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red, Colors.redAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emergency, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🆘 ${_activeSOSAlerts.length} Friend(s) Need Help!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to view emergency alerts',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _searchAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchTextController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search friends by name, username, or email...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchTextController.clear();
                        _onSearchChanged();
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Search Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          ...searchResults.map((user) => _buildSearchResultItem(user)).toList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Friend user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildProfileAvatar(user, 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _addFriend(user),
              icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search_off,
                color: Colors.white.withOpacity(0.5),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different username or email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Text(
                  isSearching ? 'Matching Friends' : 'My Friends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredFriends.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...filteredFriends.map((friend) => _buildFriendItem(friend)).toList(),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Friend friend) {
    // Check if this friend has an active SOS alert
    final hasSOS = friend.inSOS || _activeSOSAlerts.any(
      (alert) => alert.userName.toLowerCase().contains(friend.name.toLowerCase())
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasSOS 
            ? Colors.red.withOpacity(0.15) 
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSOS 
              ? Colors.red.withOpacity(0.5) 
              : Colors.white.withOpacity(0.1),
          width: hasSOS ? 2 : 1,
        ),
        boxShadow: hasSOS ? [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              _buildProfileAvatar(friend, 48),
              if (hasSOS)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF1a1a2e), width: 2),
                    ),
                    child: Icon(
                      Icons.warning,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        friend.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (hasSOS)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emergency, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: hasSOS 
                            ? Colors.red 
                            : (friend.isOnline ? Colors.green : Colors.grey),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasSOS 
                          ? 'NEEDS HELP!' 
                          : friend.lastSeen,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasSOS 
                            ? Colors.red 
                            : (friend.isOnline 
                                ? Colors.green 
                                : Colors.white.withOpacity(0.7)),
                        fontWeight: hasSOS ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        hasSOS ? Icons.warning_amber : Icons.location_on,
                        size: 12,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          friend.location,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Removed minutes/locationUpdated text here
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  '@${friend.username}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _openChat(friend),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Friend friend, double size) {
    Color avatarColor;
    switch (friend.profileColor) {
      case 'purple':
        avatarColor = Colors.deepPurple;
        break;
      case 'blue':
        avatarColor = Colors.blue;
        break;
      case 'green':
        avatarColor = Colors.green;
        break;
      case 'orange':
        avatarColor = Colors.orange;
        break;
      case 'pink':
        avatarColor = Colors.pink;
        break;
      case 'cyan':
        avatarColor = Colors.cyan;
        break;
      default:
        avatarColor = Colors.deepPurple;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [avatarColor, avatarColor.withOpacity(0.7)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: avatarColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              friend.name.split(' ').map((name) => name[0]).take(2).join(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (friend.isOnline)
            Positioned(
              bottom: size * 0.05,
              right: size * 0.05,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddFriendDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF1e1a3e),
              Color(0xFF0f0f1e),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
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
            const SizedBox(height: 20),
            const Text(
              'Add Friends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use the search bar above to find friends by their username or email address.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addFriend(Friend user) {
    HapticFeedback.lightImpact();
    setState(() {
      allFriends.add(Friend(
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        isOnline: user.isOnline,
        lastSeen: user.isOnline ? 'Online' : 'Just added',
        profileColor: user.profileColor,
        location: user.isOnline ? 'Campus Area' : 'Unknown',
        locationUpdated: user.isOnline ? 'Just now' : 'Never',
      ));
      _onSearchChanged();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${user.name} as friend'),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openChat(Friend friend) {
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          friend: friend,
          messages: chatHistory[friend.id] ?? [],
        ),
      ),
    );
  }
}

// New Chat Screen
class ChatScreen extends StatefulWidget {
  final Friend friend;
  final List<ChatMessage> messages;

  const ChatScreen({
    Key? key,
    required this.friend,
    required this.messages,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> messages;

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.messages);
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
              _buildChatHeader(),
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          _buildProfileAvatar(widget.friend, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.friend.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.friend.isOnline ? 'Online' : widget.friend.lastSeen,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.friend.isOnline 
                            ? Colors.green 
                            : Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      ' • ${widget.friend.location}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showFriendOptions(),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Friend friend, double size) {
    Color avatarColor;
    switch (friend.profileColor) {
      case 'purple':
        avatarColor = Colors.deepPurple;
        break;
      case 'blue':
        avatarColor = Colors.blue;
        break;
      case 'green':
        avatarColor = Colors.green;
        break;
      case 'orange':
        avatarColor = Colors.orange;
        break;
      case 'pink':
        avatarColor = Colors.pink;
        break;
      case 'cyan':
        avatarColor = Colors.cyan;
        break;
      default:
        avatarColor = Colors.deepPurple;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [avatarColor, avatarColor.withOpacity(0.7)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          friend.name.split(' ').map((name) => name[0]).take(2).join(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            _buildProfileAvatar(widget.friend, 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      )
                    : null,
                color: message.isMe ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == 'read' 
                              ? Icons.done_all 
                              : message.status == 'delivered'
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 14,
                          color: message.status == 'read' 
                              ? Colors.blue 
                              : Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'Me',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
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
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  prefixIcon: IconButton(
                    onPressed: () {
                      // Emoji picker or attachment
                    },
                    icon: Icon(
                      Icons.attach_file,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: _messageController.text.trim(),
          isMe: true,
          timestamp: DateTime.now(),
          status: 'sent',
        ));
      });
      
      _messageController.clear();
      
      // Auto scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Simulate friend response after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              message: _getAutoResponse(),
              isMe: false,
              timestamp: DateTime.now(),
            ));
          });
          
          // Auto scroll to bottom for response
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }
  }

  String _getAutoResponse() {
    final responses = [
      "Thanks for the message! I'm currently busy but will get back to you soon.",
      "Hey! Just saw your message. What's up?",
      "I'm at ${widget.friend.location} right now. Want to meet up?",
      "Sure thing! Let me know when you're free.",
      "That sounds great! I'll check my schedule and let you know.",
      "Thanks for checking in! I'm doing well, how about you?",
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _showFriendOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF1e1a3e),
              Color(0xFF0f0f1e),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
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
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Share Location', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location shared with friend')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk, color: Colors.green),
              title: const Text('Walk Together', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Walk request sent')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Emergency Alert', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency alert sent to friend')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}