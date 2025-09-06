// widgets/safety_chart.dart
import 'package:flutter/material.dart';

class SafetyHeatmap extends StatelessWidget {
  const SafetyHeatmap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Real campus map background with fallback
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: Image.asset(
              'images/um_campus_map.jpg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
              ),
            ),
          ),
          // Safety zones overlay
          ..._buildSafetyZones(),
          // Legend
          Positioned(
            top: 20,
            right: 20,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSafetyZones() {
    return [
      // Safe zones (Green) - Main academic buildings and security-patrolled areas
      Positioned(
        left: 300,
        top: 250,
        child: _buildSafetyZone('Faculty Buildings', Colors.green, 80, 60, 'SAFE'),
      ),
      Positioned(
        left: 420,
        top: 300,
        child: _buildSafetyZone('Sports Complex', Colors.orange, 80, 55, 'MODERATE'),
      ),
      Positioned(
        right: 290,
        top: 240,
        child: _buildSafetyZone('Main Library', Colors.green, 60, 50, 'SAFE'),
      ),
      Positioned(
        left: 370,
        bottom: 270,
        child: _buildSafetyZone('Faculty CS', Colors.green, 70, 45, 'SAFE'),
      ),
      
      // Moderate zones (Yellow/Orange) - Student areas with moderate activity
      Positioned(
        right: 280,
        bottom: 250,
        child: _buildSafetyZone('Student Hostels', Colors.orange, 90, 65, 'MODERATE'),
      ),
      Positioned(
        right: 330,
        top: 290,
        child: _buildSafetyZone('Cafeteria Area', Colors.orange, 65, 45, 'MODERATE'),
      ),
      
      // High-risk zones (Red) - Isolated areas, parking lots, late-night risk areas
      Positioned(
        left: 270,
        bottom: 180,
        child: _buildSafetyZone('Parking Area', Colors.red, 85, 50, 'HIGH RISK'),
      ),
      Positioned(
        right: 260,
        top: 180,
        child: _buildSafetyZone('Back Gate Area', Colors.red, 70, 40, 'HIGH RISK'),
      ),
      Positioned(
        left: 430,
        top: 170,
        child: _buildSafetyZone('Forest Zone', Colors.red[900]!, 80, 55, 'DANGER'),
      ),
    ];
  }

  Widget _buildSafetyZone(String name, Color color, double width, double height, String riskLevel) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                riskLevel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 7,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Safety Levels',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.green, 'Safe Areas'),
          _buildLegendItem(Colors.orange, 'Moderate Risk'),
          _buildLegendItem(Colors.yellow, 'Caution'),
          _buildLegendItem(Colors.red, 'High Risk'),
          _buildLegendItem(Colors.red[900]!, 'Danger Zone'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: color, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
