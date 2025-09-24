import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import './models.dart';
import './walk_confirmation_screen.dart';

class PartnerResultsScreen extends StatefulWidget {
  final String? destination;

  const PartnerResultsScreen({
    Key? key,
    this.destination,
  }) : super(key: key);

  @override
  _PartnerResultsScreenState createState() => _PartnerResultsScreenState();
}

class _PartnerResultsScreenState extends State<PartnerResultsScreen> {
  List<UserProfile> nearbyPartners = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyPartners();
  }

  Future<void> _loadNearbyPartners() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      nearbyPartners = [
        const UserProfile(
          id: '1',
          name: 'Sarah Chen',
          profilePicture: '👩‍🎓',
          rating: 4.8,
          walkCount: 156,
          isVerified: true,
          department: 'Computer Science',
          creditScore: 850,
          location: LatLng(3.1236, 101.6546),
          estimatedMinutes: 5,
        ),
        const UserProfile(
          id: '2',
          name: 'Ahmad Rahman',
          profilePicture: '👨‍🎓',
          rating: 4.9,
          walkCount: 203,
          isVerified: true,
          department: 'Engineering',
          creditScore: 920,
          location: LatLng(3.1224, 101.6534),
          estimatedMinutes: 8,
        ),
        const UserProfile(
          id: '3',
          name: 'Priya Sharma',
          profilePicture: '👩‍🔬',
          rating: 4.7,
          walkCount: 89,
          isVerified: false,
          department: 'Biology',
          creditScore: 780,
          location: LatLng(3.1240, 101.6520),
          estimatedMinutes: 12,
        ),
        const UserProfile(
          id: '4',
          name: 'David Lim',
          profilePicture: '👨‍💼',
          rating: 4.6,
          walkCount: 134,
          isVerified: true,
          department: 'Business',
          creditScore: 800,
          location: LatLng(3.1215, 101.6550),
          estimatedMinutes: 7,
        ),
      ];
      isLoading = false;
    });
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
              // Title Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
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
              
              // Content Section
              Expanded(
                child: isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.deepPurple),
                            SizedBox(height: 16),
                            Text(
                              'Finding nearby partners...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: nearbyPartners.length,
                        itemBuilder: (context, index) => _buildPartnerCard(nearbyPartners[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerCard(UserProfile partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectPartner(partner),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Partner Avatar
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
                    partner.profilePicture ?? partner.name[0],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Partner Info
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
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${partner.rating}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Walk Count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk, color: Colors.green, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${partner.walkCount}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
              
              // Distance and Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${partner.estimatedMinutes} min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'away',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Credit Score Indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security,
                        color: _getCreditScoreColor(partner.creditScore),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${partner.creditScore}',
                        style: TextStyle(
                          color: _getCreditScoreColor(partner.creditScore),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCreditScoreColor(int creditScore) {
    if (creditScore >= 850) return Colors.green;
    if (creditScore >= 750) return Colors.blue;
    if (creditScore >= 650) return Colors.orange;
    return Colors.red;
  }

  void _selectPartner(UserProfile partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalkConfirmationScreen(
          partner: partner,
          destination: widget.destination ?? 'Student Center',
          departureTime: DateTime.now().add(const Duration(minutes: 10)), // Default to 10 minutes from now
        ),
      ),
    );
  }
}