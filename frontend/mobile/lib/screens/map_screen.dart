import 'package:flutter/material.dart';

class SafeZone {
  final String name;
  final String distance;
  final String hours;
  final bool isOpen;
  final String status;

  SafeZone({
    required this.name,
    required this.distance,
    required this.hours,
    required this.isOpen,
    required this.status,
  });
}

class MapScreen extends StatelessWidget {
  final List<SafeZone> safeZones = [
    SafeZone(
      name: 'Security Office - Main',
      distance: '0.2 miles',
      hours: 'Open 24/7',
      isOpen: true,
      status: 'Open',
    ),
    SafeZone(
      name: 'Library Help Desk',
      distance: '0.1 miles',
      hours: 'Open until 10 PM',
      isOpen: true,
      status: 'Open',
    ),
    SafeZone(
      name: 'Student Center Desk',
      distance: '0.3 miles',
      hours: 'Open until 11 PM',
      isOpen: true,
      status: 'Closes Soon',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
        ),
        title: Text(
          'Campus Safe Zones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 48,
                    color: Colors.blue[600],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Interactive Campus Map',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '(Demo Mode - Static View)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nearby Safe Zones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: safeZones.length,
                itemBuilder: (context, index) {
                  final zone = safeZones[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zone.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[900],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${zone.distance} • ${zone.hours}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: zone.status == 'Open' 
                                    ? Colors.green 
                                    : Colors.yellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              zone.status,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: zone.status == 'Open' 
                                    ? Colors.green[600] 
                                    : Colors.yellow[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}