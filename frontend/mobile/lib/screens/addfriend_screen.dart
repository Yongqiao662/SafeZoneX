import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

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
  
  List<Friend> allFriends = []; // Will be loaded from backend
  bool _isLoadingFriends = true;
  String? _currentUserId;

  List<Friend> searchResults = [];
  List<Friend> filteredFriends = [];
  String searchQuery = '';
  bool isSearching = false;
  
  // WebSocket for real-time SOS alerts
  IO.Socket? _socket;
  List<SOSAlert> _activeSOSAlerts = [];
  bool _isConnectedToBackend = false;
  Timer? _connectionRetryTimer;

  // Chat data will be loaded from backend per friend
  Map<String, List<ChatMessage>> chatHistory = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fadeController.value = 1.0;
    _slideController.value = 1.0;
    _searchAnimationController.value = 1.0;
    _searchTextController.addListener(_onSearchChanged);
    
    // Load real friends from backend
    _loadRealFriends();
    
    // Connect to backend for real-time SOS alerts
    _connectToBackendForSOSAlerts();
  }

  Future<void> _loadRealFriends() async {
    try {
      setState(() => _isLoadingFriends = true);
      
      // Get current user ID
      _currentUserId = await ApiService.getCurrentUserId();
      
      if (_currentUserId != null) {
        final result = await ApiService.getFriends(_currentUserId!);
        
        if (result['success'] == true) {
          final friendsData = result['friends'] as List;
          
          setState(() {
            allFriends = friendsData.map((f) => Friend(
              id: f['id'] ?? '',
              name: f['name'] ?? 'Unknown',
              username: f['username'] ?? '',
              email: f['email'] ?? '',
              isOnline: f['isOnline'] ?? false,
              lastSeen: f['lastSeen'] ?? 'Unknown',
              profileColor: f['profileColor'] ?? 'blue',
              location: f['location'] ?? 'Unknown',
              locationUpdated: f['locationUpdated'] ?? 'N/A',
            )).toList();
            
            filteredFriends = allFriends;
            _isLoadingFriends = false;
          });
          
          print('✅ Loaded ${allFriends.length} friends from backend');
        }
      } else {
        print('⚠️ No user ID found, showing empty friends list');
        setState(() => _isLoadingFriends = false);
      }
    } catch (e) {
      print('❌ Error loading friends: $e');
      setState(() => _isLoadingFriends = false);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load friends. Please check your connection.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
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
        // Search in existing friends
        filteredFriends = allFriends.where((friend) =>
          friend.name.toLowerCase().contains(searchQuery) ||
          friend.username.toLowerCase().contains(searchQuery) ||
          friend.email.toLowerCase().contains(searchQuery)
        ).toList();
        
        // Search for new users via API
        _searchUsersFromAPI(searchQuery);
      }
    });
  }

  // Search for users from backend API
  Future<void> _searchUsersFromAPI(String query) async {
    if (_currentUserId == null || query.trim().isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    try {
      final result = await ApiService.searchUsers(query.trim(), _currentUserId!);
      
      if (result['success'] == true && mounted) {
        final usersData = result['users'] as List;
        
        setState(() {
          searchResults = usersData.map((u) => Friend(
            id: u['userId'] ?? '',
            name: u['name'] ?? 'Unknown',
            username: u['email']?.split('@')[0] ?? '',
            email: u['email'] ?? '',
            isOnline: false,
            lastSeen: 'Not added',
            profileColor: 'blue',
            location: 'Unknown',
            locationUpdated: 'Never',
          )).toList();
        });
      }
    } catch (e) {
      print('❌ Error searching users: $e');
      if (mounted) {
        setState(() => searchResults = []);
      }
    }
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
    // 🆕 REAL Google Maps with friend's location
    final LatLng friendLocation = LatLng(alert.latitude, alert.longitude);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${alert.userName}\'s Location',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // 🆕 REAL Google Maps
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: friendLocation,
                        zoom: 16.0,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId('sos_location'),
                          position: friendLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: InfoWindow(
                            title: '🆘 ${alert.userName}',
                            snippet: alert.address,
                          ),
                        ),
                      },
                      mapType: MapType.normal,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Address and info
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
                          Icon(Icons.location_on, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.address,
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.my_location, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
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
              onPressed: () async {
                // 🆕 REAL Google Maps Navigation
                final url = 'https://www.google.com/maps/dir/?api=1&destination=${alert.latitude},${alert.longitude}';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open maps')),
                  );
                }
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

  Future<void> _addFriend(Friend user) async {
    HapticFeedback.lightImpact();
    
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: User not logged in'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    try {
      // Get current user info
      final userName = await ApiService.getCurrentUserName();
      final userEmail = await ApiService.getCurrentUserEmail();

      // Add friend via API
      final result = await ApiService.addFriend(
        userId: _currentUserId!,
        friendEmail: user.email,
        userName: userName ?? 'User',
        userEmail: userEmail ?? '',
        profileColor: user.profileColor,
      );

      if (result['success'] == true) {
        // Reload friends list from backend
        await _loadRealFriends();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added ${user.name} as friend'),
            backgroundColor: const Color(0xFF6C5CE7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Clear search to show updated friends list
        _searchTextController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to add friend'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding friend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add friend. Please try again.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
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
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.messages);
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io('http://10.0.2.2:8080', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.connect();

    socket?.on('connect', (_) async {
      print('🔗 Connected to chat server');
      
      // Get current user ID for joining personal room
      final currentUserId = await ApiService.getCurrentUserId();
      if (currentUserId != null) {
        // Join personal room for receiving messages
        socket?.emit('join_user_room', {
          'userId': currentUserId,
          'type': 'chat'
        });
        print('🏠 Joined personal room for user: $currentUserId');
      }
      
      _loadChatHistory(); // Load chat history when connected
    });

    // Listen for incoming messages
    socket?.on('new_message', (data) {
      print('📥 Received message: $data');
      
      // Only add message if it's for this chat (from this friend)
      if (data['senderId'] == widget.friend.id) {
        setState(() {
          messages.add(ChatMessage(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            message: data['message'] ?? '',
            isMe: false,
            timestamp: data['timestamp'] != null 
                ? DateTime.parse(data['timestamp']) 
                : DateTime.now(),
            status: 'received',
          ));
        });

        // Auto scroll to bottom when receiving message
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

    socket?.on('disconnect', (_) {
      print('❌ Disconnected from chat server');
    });
  }

  // Load chat history from backend
  void _loadChatHistory() async {
    try {
      // Get current user ID from shared preferences
      final currentUserId = await ApiService.getCurrentUserId();
      
      if (currentUserId == null) {
        print('❌ No user logged in, cannot load chat history');
        return;
      }
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/messages/$currentUserId/${widget.friend.id}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['messages'] != null) {
          setState(() {
            messages = (data['messages'] as List).map((msg) => ChatMessage(
              id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              message: msg['message'] ?? '',
              isMe: msg['isMe'] ?? false,
              timestamp: msg['timestamp'] != null 
                  ? DateTime.parse(msg['timestamp']) 
                  : DateTime.now(),
              status: msg['isRead'] ? 'read' : 'sent',
            )).toList();
          });
          
          // Auto scroll to bottom after loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error loading chat history: $e');
    }
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
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
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      setState(() {
        messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: messageText,
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

      // Send message to backend for real-time delivery
      _sendMessageToBackend(messageText);
    }
  }

  // Send message to backend for real-time delivery
  void _sendMessageToBackend(String message) async {
    try {
      // Get current user ID and name from shared preferences
      final currentUserId = await ApiService.getCurrentUserId();
      final currentUserName = await ApiService.getCurrentUserName();
      
      print('🔍 Debug - User ID: $currentUserId');
      print('🔍 Debug - User Name: $currentUserName');
      print('🔍 Debug - Friend ID: ${widget.friend.id}');
      print('🔍 Debug - Message: $message');
      
      if (currentUserId == null || currentUserName == null) {
        print('❌ No user logged in, cannot send message');
        // Use fallback user ID for testing
        final fallbackUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
        final fallbackUserName = 'Test User';
        print('🔄 Using fallback user: $fallbackUserId');
        
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8080/api/messages/send'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'senderId': fallbackUserId,
            'recipientId': widget.friend.id,
            'message': message,
            'senderName': fallbackUserName,
            'messageType': 'text',
          }),
        );
        
        print('📤 Response status: ${response.statusCode}');
        print('📤 Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          print('✅ Message sent successfully with fallback user');
        } else {
          print('❌ Failed to send message: ${response.statusCode}');
        }
        return;
      }
      
      print('📤 Sending message with logged-in user...');
      
      // Update user's last seen timestamp when sending message
      socket?.emit('user_activity', {
        'userId': currentUserId,
        'activity': 'messaging',
        'timestamp': DateTime.now().toIso8601String()
      });
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/messages/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': currentUserId,
          'recipientId': widget.friend.id,
          'message': message,
          'senderName': currentUserName,
          'messageType': 'text',
        }),
      );
      
      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ Message sent successfully');
      } else {
        print('❌ Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
    }
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
}