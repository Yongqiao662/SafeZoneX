import 'package:flutter/material.dart';
import '../services/enhanced_location_tracking_service.dart';

class EnhancedLocationDashboard extends StatefulWidget {
  const EnhancedLocationDashboard({Key? key}) : super(key: key);

  @override
  State<EnhancedLocationDashboard> createState() => _EnhancedLocationDashboardState();
}

class _EnhancedLocationDashboardState extends State<EnhancedLocationDashboard> 
    with AutomaticKeepAliveClientMixin {
  final EnhancedLocationTrackingService _service = EnhancedLocationTrackingService();
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true; // Prevent unnecessary rebuilds

  @override
  void initState() {
    super.initState();
    _initializeService();
    _service.addListener(_onServiceUpdate);
  }

  Future<void> _initializeService() async {
    if (!_isInitialized) {
      await _service.initialize(
        googleMapsApiKey: 'AIzaSyAhVXxYn4NttDrHLzRHy1glc8ukrmkissM',
        backendApiUrl: 'ws://10.0.2.2:8080',
      );
      _isInitialized = true;
      
      // Start tracking immediately for real-time location
      await _service.startTracking();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    // Throttle UI updates to reduce lag
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _service.isInSafeZone ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Enhanced Location Tracking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Current Status
          _buildStatusRow(
            'Tracking Status',
            _service.isTracking ? 'Active' : 'Inactive',
            _service.isTracking ? Colors.green : Colors.grey,
          ),
          
          _buildStatusRow(
            'Emergency Mode',
            _service.isEmergencyTracking ? 'ON' : 'OFF',
            _service.isEmergencyTracking ? Colors.red : Colors.grey,
          ),
          
          _buildStatusRow(
            'Safe Zone Status',
            _service.isInSafeZone ? 'In Safe Zone' : 'Outside Safe Zone',
            _service.isInSafeZone ? Colors.green : Colors.orange,
          ),
          
          const SizedBox(height: 16),
          
          // Location Info
          if (_service.currentPosition != null) ...[
            _buildInfoCard(
              title: 'Current Location',
              content: _service.currentAddress ?? 'Loading address...',
              icon: Icons.place,
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              title: 'Coordinates',
              content: '${_service.currentPosition!.latitude.toStringAsFixed(6)}, ${_service.currentPosition!.longitude.toStringAsFixed(6)}',
              icon: Icons.gps_fixed,
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              title: 'Accuracy',
              content: '±${_service.currentPosition!.accuracy.toStringAsFixed(1)}m',
              icon: Icons.my_location,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Safe Zones
          if (_service.safeZones.isNotEmpty) ...[
            const Text(
              'Nearby Safe Zones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...(_service.safeZones.take(3).map((zone) => _buildSafeZoneCard(zone))),
          ],
          
          const SizedBox(height: 16),
          
          // Control Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _service.isTracking ? 
                    () => _service.stopTracking() : 
                    () => _service.startTracking(),
                  icon: Icon(_service.isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_service.isTracking ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _service.isTracking ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _service.startTracking(isEmergency: true),
                  icon: const Icon(Icons.emergency),
                  label: const Text('Emergency'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeZoneCard(SafeZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  zone.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${zone.radius.toInt()}m',
            style: TextStyle(
              color: Colors.green.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
