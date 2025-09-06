import 'package:flutter/material.dart';
import 'models.dart';
import 'partner_results_screen.dart';

class WalkWithMeHome extends StatefulWidget {
  @override
  _WalkWithMeHomeState createState() => _WalkWithMeHomeState();
}

class _WalkWithMeHomeState extends State<WalkWithMeHome> {
  @override
  Widget build(BuildContext context) {
    return FindWalkPage();
  }
}

class FindWalkPage extends StatefulWidget {
  @override
  _FindWalkPageState createState() => _FindWalkPageState();
}

class _FindWalkPageState extends State<FindWalkPage> {
  String? selectedDestination;
  DateTime? departureTime;
  String walkSpeed = 'normal';
  bool onlyHighCreditScore = true;
  bool onlyVerified = true;
  
  // Note: These are demo campus locations. In a real app, these would be:
  // 1. Loaded from a campus database/API
  // 2. Set to actual campus coordinates
  // 3. Configured per institution
  final List<CampusLocation> campusLocations = [
    CampusLocation(name: 'Perpustakaan Utama UM', category: 'Library', lat: 3.1235, lng: 101.6545, building: 'Main Library Building'),
    CampusLocation(name: 'Student Affairs Division', category: 'Social', lat: 3.1250, lng: 101.6540, building: 'Administration Complex'),
    CampusLocation(name: 'Faculty of Engineering', category: 'Academic', lat: 3.1240, lng: 101.6555, building: 'Engineering Complex'),
    CampusLocation(name: 'UM Cafeteria Central', category: 'Dining', lat: 3.1225, lng: 101.6535, building: 'Student Center'),
    CampusLocation(name: 'UM Sports Centre', category: 'Recreation', lat: 3.1265, lng: 101.6525, building: 'Sports Complex'),
    CampusLocation(name: 'Kolej Kediaman 4th College', category: 'Housing', lat: 3.1180, lng: 101.6570, building: 'Residential College'),
  ];

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
              // Title Section - Matching Friends page style
              Padding(
                padding: const EdgeInsets.all(20),
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
                        Icons.directions_walk,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Walk With Me',
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
              // Rest of the content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      _buildDestinationSelector(),
                      const SizedBox(height: 20),
                      _buildDepartureTimeSelector(),
                      const SizedBox(height: 20),
                      _buildPreferences(),
                      const SizedBox(height: 30),
                      _buildFindWalkButton(),
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

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_walk,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Walk Safely Together',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find verified walking partners for your campus journey',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where are you going?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          ...campusLocations.map((location) => _buildLocationTile(location)),
        ],
      ),
    );
  }

  Widget _buildLocationTile(CampusLocation location) {
    final isSelected = selectedDestination == location.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => selectedDestination = location.name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
              ? Colors.deepPurple.withOpacity(0.3) 
              : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? Colors.deepPurple 
                : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isSelected 
                    ? const LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent])
                    : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(location.category),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${location.category} • ${location.building}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Colors.blue.shade400),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Library': return Icons.local_library;
      case 'Social': return Icons.people;
      case 'Academic': return Icons.school;
      case 'Dining': return Icons.restaurant;
      case 'Recreation': return Icons.fitness_center;
      case 'Housing': return Icons.home;
      default: return Icons.location_on;
    }
  }

  Widget _buildDepartureTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When do you want to leave?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectTime(),
                  icon: const Icon(Icons.schedule, color: Colors.white),
                  label: Text(
                    departureTime == null 
                      ? 'Select Time' 
                      : '${departureTime!.hour.toString().padLeft(2, '0')}:${departureTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => setState(() => departureTime = DateTime.now()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Now',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text(
              'Only high credit score partners',
              style: TextStyle(color: Colors.white),
            ),
            value: onlyHighCreditScore,
            onChanged: (value) => setState(() => onlyHighCreditScore = value),
            activeColor: Colors.deepPurple,
          ),
          SwitchListTile(
            title: const Text(
              'Only verified users',
              style: TextStyle(color: Colors.white),
            ),
            value: onlyVerified,
            onChanged: (value) => setState(() => onlyVerified = value),
            activeColor: Colors.deepPurple,
          ),
          const SizedBox(height: 10),
          const Text(
            'Walking Speed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['slow', 'normal', 'fast'].map((speed) {
              final isSelected = walkSpeed == speed;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => setState(() => walkSpeed = speed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
                        ? Colors.deepPurple 
                        : Colors.white.withOpacity(0.1),
                    ),
                    child: Text(
                      speed.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFindWalkButton() {
    final canSearch = selectedDestination != null && departureTime != null;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSearch ? () => _findWalkingPartners() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Find Walking Partners',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        departureTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _findWalkingPartners() {
    // Navigate to partner results screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerResultsScreen(
          destination: selectedDestination!,
          departureTime: departureTime!,
          walkSpeed: walkSpeed,
          onlyHighCreditScore: onlyHighCreditScore,
          onlyVerified: onlyVerified,
        ),
      ),
    );
  }
}
