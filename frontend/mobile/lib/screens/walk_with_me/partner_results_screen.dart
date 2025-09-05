import 'package:flutter/material.dart';
import 'models.dart';
import 'partner_profile_screen.dart';
import 'walk_request_screen.dart';

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
        currentLat: 0.0, // Demo coordinates - will use actual location in real app
        currentLng: 0.0,
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
        currentLat: 0.0, // Demo coordinates - will use actual location in real app
        currentLng: 0.0,
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
        currentLat: 0.0, // Demo coordinates - will use actual location in real app
        currentLng: 0.0,
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
              // Title Section - Matching Home page style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Available Partners',
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
              // Content section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: isLoading ? _buildLoadingScreen() : _buildPartnersList(),
                ),
              ),
            ],
          ),
        ),
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
