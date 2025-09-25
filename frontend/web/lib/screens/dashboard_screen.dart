import 'package:flutter/material.dart';
import 'dart:async';
// import 'dart:async'; // Commented out for static demo
import '../models/sos_alert.dart';
import '../services/websocket_service.dart';
import '../widgets/alert_card_new.dart';
import '../widgets/safety_heatmap.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final WebSocketService _wsService = WebSocketService();
  final List<SOSAlert> _alerts = [];
  late StreamSubscription<SOSAlert> _alertSubscription;
  late StreamSubscription<String> _connectionSubscription;
  late TabController _tabController;
  
  String _connectionStatus = 'disconnected';
  int _activeAlerts = 0;
  int _acknowledgedAlerts = 0;
  int _resolvedAlerts = 0;

  // University Malaya safety data (aligned with heatmap)
  final List<Map<String, dynamic>> _umSafetyData = [
    {'area': 'Faculty Buildings', 'safetyLevel': 'Safe', 'incidents': 2, 'color': Colors.green},
    {'area': 'Main Library', 'safetyLevel': 'Safe', 'incidents': 1, 'color': Colors.green},
    {'area': 'Faculty CS', 'safetyLevel': 'Safe', 'incidents': 1, 'color': Colors.green},
    {'area': 'Sports Complex', 'safetyLevel': 'Moderate', 'incidents': 3, 'color': Colors.orange},
    {'area': 'Student Hostels', 'safetyLevel': 'Moderate', 'incidents': 5, 'color': Colors.orange},
    {'area': 'Cafeteria Area', 'safetyLevel': 'Moderate', 'incidents': 4, 'color': Colors.orange},
    {'area': 'Parking Area', 'safetyLevel': 'High Risk', 'incidents': 8, 'color': Colors.red},
    {'area': 'Back Gate Area', 'safetyLevel': 'High Risk', 'incidents': 6, 'color': Colors.red},
    {'area': 'Forest Zone', 'safetyLevel': 'Danger', 'incidents': 12, 'color': Colors.red[900]},
  ];

  @override
  void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _alertSubscription = _wsService.alertStream.listen((alert) {
      setState(() {
        _alerts.insert(0, alert);
        _updateCounts();
      });
    });

    _connectionSubscription = _wsService.connectionStream.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });

    _wsService.connect();
  }


  void _showAlertDetails(SOSAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emergency, 
              color: _getAlertStatusColor(alert.status),
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Emergency Alert Details'),
            ),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8, // Increased from 0.6 to 0.8
          height: MediaQuery.of(context).size.height * 0.8, // Added height constraint
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', alert.alertType),
                _buildDetailRow('Status', alert.status.toUpperCase()),
                _buildDetailRow('Reporter', alert.userName),
                _buildDetailRow('Phone', alert.userPhone),
                _buildDetailRow('Urgency', 'Moderate'),
                _buildDetailRow('Location', alert.address),
                _buildDetailRow('Coordinates', 
                  '${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}'),
                
                const SizedBox(height: 16),
                const Text('Additional Information:', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  width: double.infinity,
                  child: Text(
                    (alert.additionalInfo?.isNotEmpty == true) ? alert.additionalInfo! : 'No additional details provided',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                
                // Mock image section (simulating reports from mobile with images)
                const SizedBox(height: 16),
                const Text('Attached Evidence:', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  height: 400, // Increased from 200 to 400 for better image visibility
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildMockImage(alert.alertType),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Image automatically captured from mobile app',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (alert.status == 'active')
            ElevatedButton(
              onPressed: () {
                _acknowledgeAlert(alert);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Acknowledge'),
            ),
          if (alert.status == 'acknowledged')
            ElevatedButton(
              onPressed: () {
                _resolveAlert(alert);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMockImage(String alertType) {
    // Mock images based on alert type
    Map<String, Widget> mockImages = {
      'Emergency': Container(
        color: Colors.red[100],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, size: 48, color: Colors.red),
            SizedBox(height: 8),
            Text('Emergency Situation', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Text('Photo from mobile device', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      'Medical': Container(
        color: Colors.blue[100],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 48, color: Colors.blue),
            SizedBox(height: 8),
            Text('Medical Emergency', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            Text('Photo from mobile device', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      'Test': Container(
        color: Colors.green[100],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            SizedBox(height: 8),
            Text('Test Alert', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text('Mock photo for testing', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      'Safety Hazard': Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'images/street_light_issue.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.orange[100],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 48, color: Colors.orange),
                    SizedBox(height: 8),
                    Text('Faulty Street Light', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    Text('Photo from John Doe\'s mobile', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 4),
                    Text('Real-time sync from mobile app', 
                      style: TextStyle(fontSize: 10, color: Colors.blue, fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    };

    return mockImages[alertType] ?? Container(
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Alert Image', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Text('Photo from mobile device', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getAlertStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSafetyIcon(String safetyLevel) {
    switch (safetyLevel) {
      case 'Safe':
        return Icons.check_circle;
      case 'Moderate':
        return Icons.warning;
      case 'Unsafe':
        return Icons.error;
      case 'Dangerous':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  String _getLastUpdateTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _updateCounts() {
    _activeAlerts = _alerts.where((a) => a.status == 'active').length;
    _acknowledgedAlerts = _alerts.where((a) => a.status == 'acknowledged').length;
    _resolvedAlerts = _alerts.where((a) => a.status == 'resolved').length;
  }

  void _acknowledgeAlert(SOSAlert alert) {
    setState(() {
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _alerts[index] = alert.copyWith(status: 'acknowledged');
        _updateCounts();
      }
    });
    // Commented out WebSocket call for static demo
    // _wsService.acknowledgeAlert(alert.id);
  }

  void _resolveAlert(SOSAlert alert) {
    setState(() {
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _alerts[index] = alert.copyWith(status: 'resolved');
        _updateCounts();
      }
    });
    // Commented out WebSocket call for static demo
    // _wsService.resolveAlert(alert.id);
  }

  void _showMapDialog(SOSAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location: ${alert.userName}'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              Text('Address: ${alert.address}'),
              const SizedBox(height: 8),
              Text('Coordinates: ${alert.latitude}, ${alert.longitude}'),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Map View\n(Google Maps integration would go here)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Open in Google Maps
              Navigator.pop(context);
            },
            child: const Text('Open in Maps'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeZoneX Security Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emergency), text: 'Alerts'),
            Tab(icon: Icon(Icons.map), text: 'Safety Map'),
          ],
        ),
        actions: [
          // Connection Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _getConnectionColor(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getConnectionIcon(),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _connectionStatus.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(),
          _buildSafetyMapTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Test alert
                final testAlert = SOSAlert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: 'test_user',
                  userName: 'Test User',
                  userPhone: '+60123456789',
                  latitude: 3.1319,
                  longitude: 101.6841,
                  address: 'Test Location, University of Malaya',
                  timestamp: DateTime.now(),
                  alertType: 'Test',
                  status: 'active',
                  additionalInfo: 'This is a test alert',
                );
                
                setState(() {
                  _alerts.insert(0, testAlert);
                  _updateCounts();
                });
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.add_alert),
            ),
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      children: [
        // Statistics Cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Active Alerts', _activeAlerts, Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Acknowledged', _acknowledgedAlerts, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Resolved', _resolvedAlerts, Colors.green)),
            ],
          ),
        ),
        
        // Alerts List
        Expanded(
          child: _alerts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No alerts at this time',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Monitoring for emergency notifications...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return AlertCard(
                      alert: alert,
                      onAcknowledge: () => _acknowledgeAlert(alert),
                      onResolve: () => _resolveAlert(alert),
                      onViewMap: () => _showMapDialog(alert),
                      onTap: () => _showAlertDetails(alert),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSafetyMapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'University of Malaya - Safety Heatmap',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time safety analysis based on reported incidents and mobile app data',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Interactive Campus Heatmap
          Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const SafetyHeatmap(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Safe', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Moderate', Colors.orange),
              const SizedBox(width: 16),
              _buildLegendItem('Unsafe', Colors.red),
              const SizedBox(width: 16),
              _buildLegendItem('Dangerous', Colors.red[900]!),
            ],
          ),
          const SizedBox(height: 24),
          
          // Live Statistics
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Safe Zones', 
                  _umSafetyData.where((area) => area['safetyLevel'] == 'Safe').length, 
                  Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Alert Areas', 
                  _umSafetyData.where((area) => area['safetyLevel'] != 'Safe').length, 
                  Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Total Incidents', 
                  _umSafetyData.fold(0, (sum, area) => sum + (area['incidents'] as int)), 
                  Colors.red),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Detailed Area List with Enhanced Information
          const Text(
            'Campus Safety Zones - Live Updates',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ..._umSafetyData.map((area) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: area['color'],
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: area['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      area['incidents'].toString(),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'alerts',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                area['area'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getSafetyIcon(area['safetyLevel']),
                        size: 16,
                        color: area['color'],
                      ),
                      const SizedBox(width: 4),
                      Text('Safety Level: ${area['safetyLevel']}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${_getLastUpdateTime()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: area['color'],
                  ),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 12,
                      color: area['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getConnectionColor() {
    switch (_connectionStatus) {
      case 'connected':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getConnectionIcon() {
    switch (_connectionStatus) {
      case 'connected':
        return Icons.wifi;
      case 'error':
        return Icons.wifi_off;
      default:
        return Icons.wifi_protected_setup;
    }
  }

  @override
  void dispose() {
  _alertSubscription.cancel();
  _connectionSubscription.cancel();
  _tabController.dispose();
  super.dispose();
  }
}