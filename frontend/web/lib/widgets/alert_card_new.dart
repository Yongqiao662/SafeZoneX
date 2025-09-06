import 'package:flutter/material.dart';
import '../models/sos_alert.dart';

class AlertCard extends StatelessWidget {
  final SOSAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onViewMap;
  final VoidCallback? onTap;

  const AlertCard({
    Key? key,
    required this.alert,
    this.onAcknowledge,
    this.onResolve,
    this.onViewMap,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor();
    IconData statusIcon = _getStatusIcon();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border(
              left: BorderSide(
                color: statusColor,
                width: 4.0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Emergency Alert - ${alert.alertType}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alert.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Reporter Information
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${alert.userName} • ${alert.userPhone}'),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(alert.address)),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Urgency Level
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(alert).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _getUrgencyColor(alert), width: 1),
                      ),
                      child: Text(
                        _getUrgencyLevel(alert),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getUrgencyColor(alert),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                
                // Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_formatTimestamp(alert.timestamp)),
                  ],
                ),
                
                // Additional Info
                if (alert.additionalInfo?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(alert.additionalInfo!)),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    if (onViewMap != null)
                      TextButton.icon(
                        onPressed: onViewMap,
                        icon: const Icon(Icons.map),
                        label: const Text('View on Map'),
                      ),
                    const Spacer(),
                    if (alert.status == 'active' && onAcknowledge != null)
                      ElevatedButton.icon(
                        onPressed: onAcknowledge,
                        icon: const Icon(Icons.check),
                        label: const Text('Acknowledge'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (alert.status == 'acknowledged' && onResolve != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onResolve,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (alert.status) {
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

  IconData _getStatusIcon() {
    switch (alert.status) {
      case 'active':
        return Icons.emergency;
      case 'acknowledged':
        return Icons.schedule;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getUrgencyColor(SOSAlert alert) {
    // Match heatmap colors based on alert type
    switch (alert.alertType.toLowerCase()) {
      case 'safety hazard':
      case 'security breach':
        return Colors.orange; // MODERATE
      case 'medical':
      case 'emergency':
        return Colors.red; // HIGH RISK
      case 'fire':
      case 'severe weather':
        return Colors.red[900]!; // DANGER
      case 'general':
      case 'maintenance':
        return Colors.yellow; // CAUTION
      default:
        return Colors.green; // SAFE
    }
  }

  String _getUrgencyLevel(SOSAlert alert) {
    // Match heatmap urgency levels
    switch (alert.alertType.toLowerCase()) {
      case 'safety hazard':
      case 'security breach':
        return 'MODERATE';
      case 'medical':
      case 'emergency':
        return 'HIGH RISK';
      case 'fire':
      case 'severe weather':
        return 'DANGER';
      case 'general':
      case 'maintenance':
        return 'CAUTION';
      default:
        return 'SAFE';
    }
  }
}
