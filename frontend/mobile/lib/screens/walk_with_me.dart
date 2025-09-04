import 'package:flutter/material.dart';

// Data Models
class UserProfile {
  final String id;
  final String name;
  final String profilePicture;
  final int creditScore;
  final String department;
  final double currentLat;
  final double currentLng;
  final String currentLocation;
  final bool isVerified;
  final double rating;
  final int walkCount;

  UserProfile({
    required this.id,
    required this.name,
    required this.profilePicture,
    required this.creditScore,
    required this.department,
    required this.currentLat,
    required this.currentLng,
    required this.currentLocation,
    this.isVerified = false,
    this.rating = 0.0,
    this.walkCount = 0,
  });
}

class WalkRequest {
  final String id;
  final String userId;
  final String destination;
  final double destLat;
  final double destLng;
  final DateTime departureTime;
  final int maxWalkmates;
  final String walkSpeed; // slow, normal, fast
  final List<String> preferences;
  final bool isActive;

  WalkRequest({
    required this.id,
    required this.userId,
    required this.destination,
    required this.destLat,
    required this.destLng,
    required this.departureTime,
    required this.maxWalkmates,
    required this.walkSpeed,
    required this.preferences,
    this.isActive = true,
  });
}

class CampusLocation {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final String building;

  CampusLocation({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.building,
  });
}

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
  
  final List<CampusLocation> campusLocations = [
    CampusLocation(name: 'Main Library', category: 'Library', lat: 40.7128, lng: -74.0060, building: 'Building A'),
    CampusLocation(name: 'Student Union', category: 'Social', lat: 40.7130, lng: -74.0058, building: 'Building B'),
    CampusLocation(name: 'Engineering Complex', category: 'Academic', lat: 40.7125, lng: -74.0065, building: 'Building C'),
    CampusLocation(name: 'Cafeteria', category: 'Dining', lat: 40.7132, lng: -74.0062, building: 'Building D'),
    CampusLocation(name: 'Gym & Sports Center', category: 'Recreation', lat: 40.7120, lng: -74.0055, building: 'Building E'),
    CampusLocation(name: 'Dormitory Complex', category: 'Housing', lat: 40.7135, lng: -74.0070, building: 'Building F'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Walking Partners',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
      ),
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

// Partner Results Screen
class PartnerResultsScreen extends StatefulWidget {
  final String destination;
  final DateTime departureTime;
  final String walkSpeed;
  final bool onlyHighCreditScore;
  final bool onlyVerified;

  const PartnerResultsScreen({
    Key? key,
    required this.destination,
    required this.departureTime,
    required this.walkSpeed,
    required this.onlyHighCreditScore,
    required this.onlyVerified,
  }) : super(key: key);

  @override
  _PartnerResultsScreenState createState() => _PartnerResultsScreenState();
}

class _PartnerResultsScreenState extends State<PartnerResultsScreen> {
  List<UserProfile> availablePartners = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchForPartners();
  }

  void _searchForPartners() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      availablePartners = _generateMockPartners();
      isLoading = false;
    });
  }

  List<UserProfile> _generateMockPartners() {
    return [
      UserProfile(
        id: '1',
        name: 'Sarah Johnson',
        profilePicture: '👩',
        creditScore: 820,
        department: 'Computer Science',
        currentLat: 40.7128,
        currentLng: -74.0060,
        currentLocation: 'Building A',
        isVerified: true,
        rating: 4.8,
        walkCount: 15,
      ),
      UserProfile(
        id: '2',
        name: 'Mike Chen',
        profilePicture: '👨',
        creditScore: 750,
        department: 'Engineering',
        currentLat: 40.7130,
        currentLng: -74.0058,
        currentLocation: 'Building B',
        isVerified: true,
        rating: 4.6,
        walkCount: 12,
      ),
      UserProfile(
        id: '3',
        name: 'Emma Wilson',
        profilePicture: '👩‍🦱',
        creditScore: 780,
        department: 'Business',
        currentLat: 40.7125,
        currentLng: -74.0065,
        currentLocation: 'Building C',
        isVerified: false,
        rating: 4.9,
        walkCount: 8,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Partners',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: isLoading ? _buildLoadingScreen() : _buildPartnersList(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          SizedBox(height: 20),
          Text(
            'Searching for walking partners...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Going to ${widget.destination}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Departure: ${widget.departureTime.hour.toString().padLeft(2, '0')}:${widget.departureTime.minute.toString().padLeft(2, '0')} • ${widget.walkSpeed} pace',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: availablePartners.isEmpty
              ? _buildNoPartnersFound()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availablePartners.length,
                  itemBuilder: (context, index) {
                    return _buildPartnerCard(availablePartners[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNoPartnersFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person_search,
              size: 50,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No partners found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your preferences or departure time',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(UserProfile partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    partner.profilePicture,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          partner.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (partner.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partner.department,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip('Credit: ${partner.creditScore}', Colors.green),
              _buildStatChip('Rating: ${partner.rating}⭐', Colors.amber),
              _buildStatChip('${partner.walkCount} walks', Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewProfile(partner),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _requestWalk(partner),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Request Walk',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _viewProfile(UserProfile partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerProfileScreen(partner: partner),
      ),
    );
  }

  void _requestWalk(UserProfile partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalkRequestScreen(
          partner: partner,
          destination: widget.destination,
          departureTime: widget.departureTime,
        ),
      ),
    );
  }
}

// Partner Profile Screen
class PartnerProfileScreen extends StatelessWidget {
  final UserProfile partner;

  const PartnerProfileScreen({Key? key, required this.partner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          partner.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          partner.profilePicture,
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          partner.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (partner.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      partner.department,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Credit Score', partner.creditScore.toString(), Colors.green),
                        _buildStatItem('Rating', '${partner.rating}⭐', Colors.amber),
                        _buildStatItem('Walks', partner.walkCount.toString(), Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
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
                      'Safety Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.location_on, 'Current Location', partner.currentLocation),
                    _buildInfoRow(Icons.star, 'Average Rating', '${partner.rating} out of 5'),
                    _buildInfoRow(Icons.directions_walk, 'Total Walks', '${partner.walkCount} completed'),
                    _buildInfoRow(Icons.verified_user, 'Verification', partner.isVerified ? 'Verified' : 'Not Verified'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Walk Request Screen
class WalkRequestScreen extends StatefulWidget {
  final UserProfile partner;
  final String destination;
  final DateTime departureTime;

  const WalkRequestScreen({
    Key? key,
    required this.partner,
    required this.destination,
    required this.departureTime,
  }) : super(key: key);

  @override
  _WalkRequestScreenState createState() => _WalkRequestScreenState();
}

class _WalkRequestScreenState extends State<WalkRequestScreen> {
  String message = '';
  bool isRequestSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        title: const Text(
          'Walk Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
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
        child: isRequestSent ? _buildRequestSentScreen() : _buildRequestForm(),
      ),
    );
  }

  Widget _buildRequestForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          widget.partner.profilePicture,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Walking with ${widget.partner.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To ${widget.destination}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'At ${widget.departureTime.hour.toString().padLeft(2, '0')}:${widget.departureTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
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
                  'Add a message (optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => message = value,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Hi! Would you like to walk together to ${widget.destination}?',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Walk Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSentScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Request Sent!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your walk request has been sent to ${widget.partner.name}.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified when they respond.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Go Home',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ActiveWalkScreen(partner: widget.partner)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Track Walk',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendRequest() {
    setState(() {
      isRequestSent = true;
    });
  }
}

// Active Walk Screen
class ActiveWalkScreen extends StatefulWidget {
  final UserProfile partner;

  const ActiveWalkScreen({Key? key, required this.partner}) : super(key: key);

  @override
  _ActiveWalkScreenState createState() => _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen> {
  bool isWalkActive = true;
  int walkDuration = 0;
  late Stream<int> _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        title: const Text(
          'Active Walk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
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
          child: StreamBuilder<int>(
            stream: _timer,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                walkDuration = snapshot.data!;
              }
              return _buildWalkInterface();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWalkInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Walking with ${widget.partner.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          widget.partner.profilePicture,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.directions_walk,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          '👤',
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Duration: ${(walkDuration ~/ 60).toString().padLeft(2, '0')}:${(walkDuration % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Safety Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEmergencyDialog(),
                        icon: const Icon(Icons.emergency, color: Colors.white),
                        label: const Text(
                          'Emergency',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showLocationShare(),
                        icon: const Icon(Icons.location_on, color: Colors.white),
                        label: const Text(
                          'Share Location',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _completeWalk(),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'Complete Walk',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text('This will alert campus security and your emergency contacts. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger emergency alert
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _showLocationShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared with emergency contacts'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _completeWalk() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WalkCompletedScreen(
          partner: widget.partner,
          duration: walkDuration,
        ),
      ),
    );
  }
}

// Walk Completed Screen
class WalkCompletedScreen extends StatelessWidget {
  final UserProfile partner;
  final int duration;

  const WalkCompletedScreen({
    Key? key,
    required this.partner,
    required this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Walk Completed',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.lightGreen],
                    ),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Walk Completed Successfully!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'You walked safely with ${partner.name}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Walk Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSummaryItem('Duration', '${(duration ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}'),
                          _buildSummaryItem('Partner', partner.name),
                          _buildSummaryItem('Safety', '100%'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Rate your walking experience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        // Handle rating
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}