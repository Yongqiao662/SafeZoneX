import 'package:flutter/material.dart';
import '../models/sos_alert.dart';

class AlertCard extends StatelessWidget {
  final SOSAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onViewMap;

  const AlertCard({
    Key? key,
    required this.alert,
    this.onAcknowledge,
    this.onResolve,
    this.onViewMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor();
    IconData statusIcon = _getStatusIcon();

    return Card(
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      alert.status.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: statusColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // User Information
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    alert.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.phone, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  SelectableText(
                    alert.userPhone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Location Information
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${alert.latitude.toStringAsFixed(6)}, Lng: ${alert.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Timestamp
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(alert.timestamp),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              // Additional Info
              if (alert.additionalInfo != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.additionalInfo!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onViewMap != null)
                    TextButton.icon(
                      onPressed: onViewMap,
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('View on Map'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (alert.status == 'active' && onAcknowledge != null)
                    ElevatedButton.icon(
                      onPressed: onAcknowledge,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Acknowledge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (alert.status != 'resolved' && onResolve != null)
                    ElevatedButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Resolve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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
}
