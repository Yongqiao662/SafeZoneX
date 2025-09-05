import 'package:flutter/material.dart';
import '../services/location_tracking_service.dart';
import '../services/websocket_service.dart';

class LocationTrackingWidget extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhone;
  final bool isEmergencyMode;
  final VoidCallback? onLocationUpdate;

  const LocationTrackingWidget({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.isEmergencyMode = false,
    this.onLocationUpdate,
  }) : super(key: key);

  @override
  State<LocationTrackingWidget> createState() => _LocationTrackingWidgetState();
}

class _LocationTrackingWidgetState extends State<LocationTrackingWidget> {
  final LocationTrackingService _locationService = LocationTrackingService();
  final WebSocketService _wsService = WebSocketService();

  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  Color _statusColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    try {
      // Initialize location service
      final success = await _locationService.initialize();
      
      if (success) {
        // Set up location update callbacks
        _locationService.onLocationUpdate = (position, address) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Location: ${address ?? 'Address unavailable'}';
              _statusColor = Colors.green;
            });
          }

          // Send location updates via WebSocket
          _wsService.sendLocationUpdate(
            userId: widget.userId,
            latitude: position.latitude,
            longitude: position.longitude,
            address: address ?? 'Address unavailable',
            status: widget.isEmergencyMode ? 'emergency_tracking' : 'normal_tracking',
            additionalData: {
              'accuracy': position.accuracy,
              'altitude': position.altitude,
              'speed': position.speed,
              'heading': position.heading,
            },
          );

          widget.onLocationUpdate?.call();
        };

        _locationService.onLocationError = (error) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Error: $error';
              _statusColor = Colors.red;
            });
          }
        };

        _locationService.onTrackingStateChanged = (isEmergency) {
          if (mounted) {
            setState(() {
              if (_locationService.isTracking) {
                _statusMessage = isEmergency ? 'Emergency tracking active' : 'Location tracking active';
                _statusColor = isEmergency ? Colors.red : Colors.blue;
              } else {
                _statusMessage = 'Tracking stopped';
                _statusColor = Colors.grey;
              }
            });
          }
        };

        // Start tracking if in emergency mode
        if (widget.isEmergencyMode) {
          await _locationService.startTracking(isEmergency: true);
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _statusMessage = 'Location service ready';
            _statusColor = Colors.green;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = _locationService.locationError ?? 'Failed to initialize location service';
            _statusColor = Colors.red;
            _isInitialized = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Initialization error: $e';
          _statusColor = Colors.red;
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _toggleTracking() async {
    if (_locationService.isTracking) {
      _locationService.stopTracking();
    } else {
      await _locationService.startTracking(isEmergency: widget.isEmergencyMode);
    }
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      await _wsService.sendSOSAlertWithRealLocation(
        userId: widget.userId,
        userName: widget.userName,
        userPhone: widget.userPhone,
        alertType: 'Emergency SOS with Live Tracking',
        additionalInfo: 'Emergency alert with real-time location tracking activated',
      );

      // Start emergency tracking
      if (!_locationService.isTracking) {
        await _locationService.startTracking(isEmergency: true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Emergency alert sent with live location!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Text('Failed to send emergency alert: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Clear callbacks to prevent setState calls after dispose
    _locationService.onLocationUpdate = null;
    _locationService.onLocationError = null;
    _locationService.onTrackingStateChanged = null;
    
    // Don't stop tracking in dispose unless specifically requested
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _locationService.isTracking ? Icons.location_on : Icons.location_off,
                color: _statusColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Location Tracking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (_locationService.isTracking)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isEmergencyMode ? Colors.red : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.isEmergencyMode ? 'EMERGENCY' : 'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          // Status message
          Text(
            _statusMessage,
            style: TextStyle(
              color: _statusColor,
              fontSize: 14,
            ),
          ),

          if (_isInitialized && _locationService.currentPosition != null) ...[
            SizedBox(height: 8),
            
            // Location details
            Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.white.withOpacity(0.7), size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'GPS: ${_locationService.currentPosition!.latitude.toStringAsFixed(6)}, '
                    '${_locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 4),

            Row(
              children: [
                Icon(Icons.my_location, color: Colors.white.withOpacity(0.7), size: 16),
                SizedBox(width: 6),
                Text(
                  'Accuracy: ${_locationService.currentPosition!.accuracy.toStringAsFixed(1)}m',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Toggle tracking button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isInitialized ? _toggleTracking : null,
                  icon: Icon(
                    _locationService.isTracking ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    _locationService.isTracking ? 'Stop Tracking' : 'Start Tracking',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _locationService.isTracking ? Colors.red.withOpacity(0.8) : Colors.blue.withOpacity(0.8),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Emergency alert button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isInitialized ? _sendEmergencyAlert : null,
                  icon: Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    'SOS Alert',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.9),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Permission request buttons
          if (!_isInitialized) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _locationService.openLocationSettings(),
                    icon: Icon(Icons.location_on, color: Colors.orange, size: 16),
                    label: Text(
                      'Enable Location',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _locationService.openAppSettings(),
                    icon: Icon(Icons.settings, color: Colors.orange, size: 16),
                    label: Text(
                      'App Settings',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
