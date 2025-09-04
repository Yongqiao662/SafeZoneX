import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sos_alert.dart';
import '../services/websocket_service.dart';
import '../widgets/alert_card.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WebSocketService _wsService = WebSocketService();
  final List<SOSAlert> _alerts = [];
  late StreamSubscription<SOSAlert> _alertSubscription;
  late StreamSubscription<String> _connectionSubscription;
  String _connectionStatus = 'disconnected';
  int _activeAlerts = 0;
  int _acknowledgedAlerts = 0;
  int _resolvedAlerts = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _loadMockData(); // For testing purposes
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

  void _loadMockData() {
    // Add some mock data for demonstration
    final mockAlerts = [
      SOSAlert(
        id: '1',
        userId: 'user_123',
        userName: 'John Smith',
        userPhone: '+1234567890',
        latitude: 37.7749,
        longitude: -122.4194,
        address: 'Campus Library, University Ave',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        alertType: 'Emergency',
        status: 'active',
        additionalInfo: 'Suspicious person following me',
      ),
      SOSAlert(
        id: '2',
        userId: 'user_456',
        userName: 'Sarah Johnson',
        userPhone: '+1987654321',
        latitude: 37.7849,
        longitude: -122.4094,
        address: 'Student Dormitory, Building A',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        alertType: 'Medical',
        status: 'acknowledged',
        additionalInfo: 'Feeling dizzy and nauseous',
      ),
    ];

    setState(() {
      _alerts.addAll(mockAlerts);
      _updateCounts();
    });
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
    _wsService.acknowledgeAlert(alert.id);
  }

  void _resolveAlert(SOSAlert alert) {
    setState(() {
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _alerts[index] = alert.copyWith(status: 'resolved');
        _updateCounts();
      }
    });
    _wsService.resolveAlert(alert.id);
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
        title: const Text('SafeZoneX Emergency Monitor'),
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
      body: Column(
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
                        Icon(Icons.security, size: 64, color: Colors.white54),
                        SizedBox(height: 16),
                        Text(
                          'No alerts at this time',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Monitoring for emergency notifications...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Test alert
          final testAlert = SOSAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: 'test_user',
            userName: 'Test User',
            userPhone: '+1234567890',
            latitude: 37.7749,
            longitude: -122.4194,
            address: 'Test Location',
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
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
    super.dispose();
  }
}
