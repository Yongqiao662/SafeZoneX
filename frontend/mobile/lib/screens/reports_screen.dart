import '../services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/backend_api_service.dart';
import '../services/location_tracking_service.dart';
import '../services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _authInitialized = false;
  bool _isAuthenticated = false;
  late final WebSocketService _webSocketService;
  String? _reportStatus;
  double? _reportConfidence;
  String? _reportDetails;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _selectedActivity;
  String? _selectedLocation;
  Position? _currentPosition;
  String _currentLocationName = "Getting location...";
  final TextEditingController _descriptionController = TextEditingController();
  bool _isGettingLocation = false;
  
  // Campus locations for manual selection
  final List<Map<String, dynamic>> _campusLocations = [
    {
      'name': 'UM Security Office - Main Campus',
      'building': 'Security Complex',
      'coordinates': {'lat': 3.1220, 'lng': 101.6530},
    },
    {
      'name': 'Perpustakaan Utama UM',
      'building': 'Main Library Building',
      'coordinates': {'lat': 3.1235, 'lng': 101.6545},
    },
    {
      'name': 'Faculty of Engineering',
      'building': 'Engineering Complex',
      'coordinates': {'lat': 3.1240, 'lng': 101.6555},
    },
    {
      'name': 'Student Affairs Division',
      'building': 'Administration Complex',
      'coordinates': {'lat': 3.1250, 'lng': 101.6540},
    },
    {
      'name': 'UM Sports Centre',
      'building': 'Sports Complex',
      'coordinates': {'lat': 3.1265, 'lng': 101.6525},
    },
    {
      'name': 'UM Medical Centre',
      'building': 'Medical Complex',
      'coordinates': {'lat': 3.1195, 'lng': 101.6485},
    },
    {
      'name': 'Kolej Kediaman 4th College',
      'building': 'Residential College',
      'coordinates': {'lat': 3.1180, 'lng': 101.6570},
    },
    {
      'name': 'Dewan Tunku Canselor',
      'building': 'Event Hall',
      'coordinates': {'lat': 3.1210, 'lng': 101.6520},
    },
  ];
  
  final List<Map<String, dynamic>> _suspiciousActivities = [
    {
      'title': 'Suspicious Person',
      'icon': Icons.person_search,
      'description': 'Person acting suspiciously or loitering',
      'color': Color(0xFF6C5CE7),
    },
    {
      'title': 'Theft/Robbery',
      'icon': Icons.security,
      'description': 'Witnessed theft or robbery attempt',
      'color': Color(0xFFE17055),
    },
    {
      'title': 'Vandalism',
      'icon': Icons.broken_image,
      'description': 'Property damage or graffiti',
      'color': Color(0xFF74B9FF),
    },
    {
      'title': 'Drug Activity',
      'icon': Icons.warning,
      'description': 'Suspected drug-related activity',
      'color': Color(0xFFE84393),
    },
    {
      'title': 'Harassment',
      'icon': Icons.report_problem,
      'description': 'Harassment or inappropriate behavior',
      'color': Color(0xFFEB5757),
    },
    {
      'title': 'Safety Hazard',
      'icon': Icons.dangerous,
      'description': 'Physical hazards or dangerous conditions',
      'color': Color(0xFFF2994A),
    },
    {
      'title': 'Unauthorized Access',
      'icon': Icons.lock_open,
      'description': 'Someone accessing restricted areas',
      'color': Color(0xFF9B59B6),
    },
    {
      'title': 'Other',
      'icon': Icons.more_horiz,
      'description': 'Other suspicious or concerning activity',
      'color': Color(0xFF2C3E50),
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    AuthService().initialize().then((success) {
      setState(() {
        _authInitialized = true;
        _isAuthenticated = AuthService().isAuthenticated;
      });
    });

    _webSocketService = WebSocketService();
    final token = 'your_jwt_token_here';
    _webSocketService.connect(token);
    _webSocketService.messageStream.listen((message) {
      if (message['type'] == 'report_update') {
        setState(() {
          _reportStatus = message['status'];
          _reportConfidence = message['aiAnalysis']?['confidence']?.toDouble();
          _reportDetails = message['aiAnalysis']?['details'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report update: $_reportStatus ($_reportConfidence%)'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _webSocketService.dispose();
    super.dispose();
  }

  // IMPROVED GPS location method
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _currentLocationName = "Getting GPS location...";
    });

    try {
      print('🌍 Starting location acquisition...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services disabled');
        setState(() {
          _currentLocationName = "Location services disabled - Enable GPS";
          _isGettingLocation = false;
        });
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          setState(() {
            _currentLocationName = "Location permission denied";
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        setState(() {
          _currentLocationName = "Location permission permanently denied";
          _isGettingLocation = false;
        });
        return;
      }

      print('✅ Location permissions granted');

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15), // Increased timeout
      );

      print('📍 GPS coordinates received: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m');

      setState(() {
        _currentPosition = position;
        _currentLocationName = _getLocationDescription(position);
        _selectedLocation = "Current Location: $_currentLocationName";
        _isGettingLocation = false;
      });

      print('✅ Location set: $_currentLocationName');

    } catch (e) {
      print('❌ GPS error: $e');
      setState(() {
        _currentLocationName = "GPS unavailable - Using campus location";
        _isGettingLocation = false;
        // Set fallback to University Malaya coordinates
        _currentPosition = Position(
          latitude: 3.1319,
          longitude: 101.6841,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _selectedLocation = "Current Location: University Malaya Campus (Fallback)";
      });
    }
  }

  String _getLocationDescription(Position position) {
    double minDistance = double.infinity;
    String closestLocation = "Campus Area";

    for (var location in _campusLocations) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location['coordinates']['lat'],
        location['coordinates']['lng'],
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestLocation = location['name'];
      }
    }

    return "$closestLocation (${minDistance.round()}m away)";
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF1e1a3e),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Add Photo Evidence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageSourceButton(
                            icon: Icons.camera_alt,
                            title: 'Camera',
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildImageSourceButton(
                            icon: Icons.photo_library,
                            title: 'Gallery',
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // IMPROVED submit report with better location handling
  void _submitReport() async {
    print('=== SUBMIT REPORT DEBUG ===');
    
    if (_selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a type of suspicious activity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If GPS location is still being acquired, wait or use fallback
    if (_isGettingLocation) {
      print('⏳ Still getting location, trying once more...');
      await _getCurrentLocation();
    }

    // Get user profile
    final userProfile = {
      'userId': 'test_user_123',
      'userName': 'Test User',
      'userPhone': '+60123456789',
    };

    // IMPROVED location data handling
    Map<String, double> locationData;

    if (_currentPosition != null) {
      locationData = {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      };
      print('✅ Using GPS coordinates: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    } else {
      // Force get fresh location one more time
      print('⚠️ No GPS position, forcing fresh location...');
      final locationService = LocationTrackingService();
      await locationService.initialize();
      await locationService.getCurrentLocation();
      final emergencyData = locationService.getEmergencyLocationData();
      
      locationData = {
        'latitude': (emergencyData['latitude'] != 0.0 ? emergencyData['latitude'] : 3.1319).toDouble(),
        'longitude': (emergencyData['longitude'] != 0.0 ? emergencyData['longitude'] : 101.6841).toDouble(),
      };
      print('📍 Using location service coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
    }

    print('📤 Final location data: $locationData');

    final apiService = BackendApiService();
    apiService.submitSecurityReport(
      text: _descriptionController.text.trim(),
      location: locationData,
      userProfile: userProfile,
      metadata: {
        'activityType': _selectedActivity,
        'locationName': _selectedLocation,
        'alertType': _selectedActivity,
        'priority': 'normal',
      },
    ).then((result) {
      print('API Response: $result');
      if (result['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xFF1a1a2e),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'Report Submitted',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'Thank you for keeping our campus safe. Security has been notified and will investigate.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedImage = null;
                    _selectedActivity = null;
                    _descriptionController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }).catchError((e) {
      print('API Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
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
              if (_reportStatus != null)
                Container(
                  width: double.infinity,
                  color: Colors.blue.withOpacity(0.1),
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Status: $_reportStatus | Confidence: ${_reportConfidence?.toStringAsFixed(1) ?? '-'}%\n${_reportDetails ?? ''}',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
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
                        Icons.report_problem,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Reports',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Campus Safety Report',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Help keep University Malaya safe by reporting suspicious activities',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      Text(
                        'Type of Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _suspiciousActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _suspiciousActivities[index];
                          final isSelected = _selectedActivity == activity['title'];
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedActivity = activity['title'];
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activity['color'].withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? activity['color']
                                      : Colors.white.withOpacity(0.1),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    activity['icon'],
                                    color: isSelected
                                        ? activity['color']
                                        : Colors.white70,
                                    size: 28,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    activity['title'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? activity['color']
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      Text(
                        'Incident Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: _isGettingLocation 
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                    ),
                                  )
                                : Icon(Icons.my_location, color: Colors.blue),
                              title: Text(
                                'Use Current Location',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                _currentLocationName,
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              trailing: Radio<String>(
                                value: "Current Location: $_currentLocationName",
                                groupValue: _selectedLocation,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLocation = value;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                              onTap: () {
                                if (!_isGettingLocation) {
                                  setState(() {
                                    _selectedLocation = "Current Location: $_currentLocationName";
                                  });
                                }
                              },
                            ),
                            Divider(color: Colors.white.withOpacity(0.1), height: 1),
                            ListTile(
                              leading: Icon(Icons.location_on, color: Colors.orange),
                              title: Text(
                                'Choose Campus Location',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                _selectedLocation != null && !_selectedLocation!.startsWith("Current Location") 
                                  ? _selectedLocation! 
                                  : 'Select from campus locations',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                              onTap: _showLocationSelectionDialog,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      Text(
                        'Photo Evidence (Optional)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedImage != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_selectedImage!.path),
                                        width: double.infinity,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white60,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to add photo',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: 24),

                      Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Describe what you observed, when and where it happened...',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Submit Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.emergency, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'For immediate emergencies, call 999 or use the Emergency button',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF1e1a3e),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Campus Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _campusLocations.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final location = _campusLocations[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        location['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        location['building'],
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedLocation = location['name'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}