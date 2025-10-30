import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  LatLng? selectedLatLng;
  DateTime? departureTime;
  String walkSpeed = 'normal';
  bool onlyHighCreditScore = true;
  bool onlyVerified = true;
  
 
  // Enhanced UM Campus Locations - Option A: Essential Buildings
  final List<CampusLocation> campusLocations = [
    // Academic Buildings - Major Faculties
    CampusLocation(name: 'Faculty of Engineering', category: 'Academic', lat: 3.1210, lng: 101.6535, building: 'Engineering Complex'),
    CampusLocation(name: 'Faculty of Medicine', category: 'Academic', lat: 3.1240, lng: 101.6520, building: 'Medical Center'),
    CampusLocation(name: 'Faculty of Law', category: 'Academic', lat: 3.1195, lng: 101.6545, building: 'Law Building'),
    CampusLocation(name: 'Faculty of Business & Economics', category: 'Academic', lat: 3.1215, lng: 101.6525, building: 'FBE Complex'),
    CampusLocation(name: 'Faculty of Computer Science & IT', category: 'Academic', lat: 3.1230, lng: 101.6540, building: 'FSKTM Building'),
    
    // Libraries
    CampusLocation(name: 'Perpustakaan Utama UM (Central Library)', category: 'Library', lat: 3.1203, lng: 101.6539, building: 'Central Library'),
    CampusLocation(name: 'Medical Library', category: 'Library', lat: 3.1242, lng: 101.6518, building: 'Medical Center'),
    CampusLocation(name: 'Engineering Library', category: 'Library', lat: 3.1212, lng: 101.6533, building: 'Engineering Complex'),
    
    // Student Housing - Residential Colleges
    CampusLocation(name: 'Kolej Kediaman Pertama (KK1)', category: 'Housing', lat: 3.1250, lng: 101.6580, building: 'First College'),
    CampusLocation(name: 'Kolej Kediaman Kedua (KK2)', category: 'Housing', lat: 3.1245, lng: 101.6575, building: 'Second College'),
    CampusLocation(name: 'Kolej Kediaman Ketiga (KK3)', category: 'Housing', lat: 3.1248, lng: 101.6585, building: 'Third College'),
    CampusLocation(name: 'Kolej Kediaman Keempat (KK4)', category: 'Housing', lat: 3.1240, lng: 101.6599, building: 'Fourth College'),
    CampusLocation(name: 'Kolej Kediaman Kelima (KK5)', category: 'Housing', lat: 3.1260, lng: 101.6570, building: 'Fifth College'),
    CampusLocation(name: 'Kolej Kediaman Keenam (KK6)', category: 'Housing', lat: 3.1255, lng: 101.6590, building: 'Sixth College'),
    CampusLocation(name: 'Kolej Kediaman Ketujuh (KK7)', category: 'Housing', lat: 3.1235, lng: 101.6610, building: 'Seventh College'),
    CampusLocation(name: 'Kolej Kediaman Kelapan (KK8)', category: 'Housing', lat: 3.1230, lng: 101.6605, building: 'Eighth College'),
    CampusLocation(name: 'Kolej Kediaman Kesembilan (KK9)', category: 'Housing', lat: 3.1265, lng: 101.6575, building: 'Ninth College'),
    CampusLocation(name: 'Kolej Kediaman Kesepuluh (KK10)', category: 'Housing', lat: 3.1270, lng: 101.6580, building: 'Tenth College'),
    CampusLocation(name: 'Kolej Kediaman Kesebelas (KK11)', category: 'Housing', lat: 3.1225, lng: 101.6615, building: 'Eleventh College'),
    CampusLocation(name: 'Kolej Kediaman Keduabelas (KK12)', category: 'Housing', lat: 3.1220, lng: 101.6620, building: 'Twelfth College'),
    CampusLocation(name: 'Kolej Kediaman Ke-13 (KK13)', category: 'Housing', lat: 3.1275, lng: 101.6585, building: 'Thirteenth College'),
    
    // Dining Areas
    CampusLocation(name: 'Dewan Selera Siswa (Main Food Court)', category: 'Dining', lat: 3.1195, lng: 101.6538, building: 'Student Center'),
    CampusLocation(name: 'KK5 Cafeteria', category: 'Dining', lat: 3.1262, lng: 101.6568, building: 'Fifth College'),
    CampusLocation(name: 'Medical Cafeteria', category: 'Dining', lat: 3.1238, lng: 101.6522, building: 'Medical Center'),
    
    // Recreation & Sports
    CampusLocation(name: 'UM Sports Centre', category: 'Recreation', lat: 3.1226, lng: 101.6592, building: 'Sports Complex'),
    CampusLocation(name: 'Swimming Pool Complex', category: 'Recreation', lat: 3.1228, lng: 101.6590, building: 'Aquatic Center'),
    CampusLocation(name: 'Stadium Malawati UM', category: 'Recreation', lat: 3.1220, lng: 101.6595, building: 'Main Stadium'),
    
    // Essential Services
    CampusLocation(name: 'Student Affairs Division', category: 'Services', lat: 3.1198, lng: 101.6540, building: 'Administration Complex'),
    CampusLocation(name: 'UM Health Center', category: 'Services', lat: 3.1205, lng: 101.6535, building: 'Health Center'),
    CampusLocation(name: 'UM Post Office', category: 'Services', lat: 3.1200, lng: 101.6542, building: 'Administration Complex'),
    CampusLocation(name: 'UM Bank (Maybank)', category: 'Services', lat: 3.1197, lng: 101.6538, building: 'Student Center'),
    
    // Main Campus Buildings
    CampusLocation(name: 'Dewan Tunku Canselor (DTC)', category: 'Academic', lat: 3.1225, lng: 101.6532, building: 'Main Campus'),
    CampusLocation(name: 'Canselori Building', category: 'Academic', lat: 3.1190, lng: 101.6545, building: 'Administration'),
  ];

  // Local campus search state (removed Google Places)
  List<CampusLocation> _filteredLocations = [];
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearchResults = false;
  
  // Favorites functionality
  Set<String> _favoriteLocations = {};
  bool _showFavoritesOnly = false;
  bool _showAllLocations = false; // Toggle to show all vs featured locations

  // Featured locations (most commonly used)
  List<String> get featuredLocationNames => [
    'Perpustakaan Utama UM (Central Library)',
    'Faculty of Engineering',
    'Dewan Selera Siswa (Main Food Court)',
    'UM Sports Centre',
    'Kolej Kediaman Keempat (KK4)',
    'Faculty of Computer Science & IT',
  ];

  List<CampusLocation> get featuredLocations => 
      campusLocations.where((loc) => featuredLocationNames.contains(loc.name)).toList();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _filteredLocations = campusLocations; // Initialize with all locations
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
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome card as part of scrollable content
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      _buildDestinationSelector(),
                      const SizedBox(height: 20),
                      _buildDepartureTimeSelector(),
                      const SizedBox(height: 20),
                      _buildPreferences(),
                      const SizedBox(height: 30),
                      _buildFindWalkButton(),
                      const SizedBox(height: 20), // Extra space at bottom
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
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(32),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
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
          const SizedBox(height: 20),
          const Text(
            'Walk Safely Together',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find study partners to walk with\naround UM campus safely',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.3,
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
          Row(
            children: [
              const Text(
                'Where are you going?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (selectedDestination != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: Colors.green, size: 16),
              ],
            ],
          ),
          if (selectedDestination != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: $selectedDestination',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Campus-only search box
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search campus locations',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () => _clearSearch(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => _onCampusSearchChanged(v),
            onTap: () => setState(() => _showSearchResults = true),
          ),
          if (_showSearchResults && _filteredLocations.isNotEmpty && _searchCtrl.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _filteredLocations.length,
                  itemBuilder: (context, i) {
                    final location = _filteredLocations[i];
                    final isFavorite = _favoriteLocations.contains(location.name);
                    
                    return Container(
                      height: 60, // Fixed height to prevent overflow
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Icon(_getCategoryIcon(location.category), color: Colors.white70, size: 18),
                        title: Text(
                          location.name, 
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          '${location.category} • ${location.building}', 
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: SizedBox(
                          width: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Favorite star button in search results
                              GestureDetector(
                                onTap: () {
                                  _toggleFavorite(location.name);
                                  // Keep search results open after favoriting
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isFavorite 
                                        ? Colors.amber.withOpacity(0.2) 
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: isFavorite 
                                          ? Colors.amber.withOpacity(0.5) 
                                          : Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.star : Icons.star_border,
                                    color: isFavorite ? Colors.amber : Colors.white.withOpacity(0.7),
                                    size: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Select arrow
                              Icon(
                                Icons.arrow_forward_ios, 
                                color: Colors.white.withOpacity(0.4), 
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                        onTap: () => _selectCampusLocation(location),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Location list controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showFavoritesOnly 
                          ? 'Favorite Locations' 
                          : _showAllLocations 
                              ? 'All Campus Locations' 
                              : 'Popular Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (!_showFavoritesOnly)
                      Text(
                        'Tap ⭐ to favorite locations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Favorites toggle
                  GestureDetector(
                    onTap: () => setState(() {
                      _showFavoritesOnly = !_showFavoritesOnly;
                      if (_showFavoritesOnly) _showAllLocations = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: _showFavoritesOnly ? Colors.amber : Colors.white.withOpacity(0.4),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Favs',
                            style: TextStyle(
                              fontSize: 12,
                              color: _showFavoritesOnly ? Colors.amber : Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Show all toggle
                  GestureDetector(
                    onTap: () => setState(() {
                      _showAllLocations = !_showAllLocations;
                      if (_showAllLocations) _showFavoritesOnly = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        _showAllLocations ? 'Less' : 'More',
                        style: TextStyle(
                          fontSize: 12,
                          color: _showAllLocations ? Colors.blue.shade300 : Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location list based on current filter
          ...(_getDisplayLocations()).map((location) => _buildLocationTile(location)),
        ],
      ),
    );
  }

  Widget _buildLocationTile(CampusLocation location) {
    final isSelected = selectedDestination == location.name;
    final isFavorite = _favoriteLocations.contains(location.name);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          print('🎯 Location selected: ${location.name}');
          setState(() {
            selectedDestination = location.name;
            selectedLatLng = LatLng(location.lat, location.lng);
            _searchCtrl.text = location.name;
            _showSearchResults = false; // Hide search results after selection
          });
          // Show confirmation
          _showSnackBar('Selected: ${location.name}', Icons.location_on, Colors.green);
        },
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
              // Favorite star button - more prominent
              GestureDetector(
                onTap: () => _toggleFavorite(location.name),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFavorite 
                        ? Colors.amber.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFavorite 
                          ? Colors.amber.withOpacity(0.5) 
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : Colors.white.withOpacity(0.8),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
      case 'Services': return Icons.local_hospital; // For health center, bank, etc.
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
    final hasDestination = selectedDestination != null || selectedLatLng != null;
    final hasTime = departureTime != null;
    final canSearch = hasDestination && hasTime;
    
    String buttonText;
    if (!hasDestination && !hasTime) {
      buttonText = 'Select Location & Time';
    } else if (!hasDestination) {
      buttonText = 'Select a Location First';
    } else if (!hasTime) {
      buttonText = 'Select Departure Time';
    } else {
      buttonText = 'Find Walking Partners';
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSearch ? () => _findWalkingPartners() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSearch ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canSearch) 
              const Icon(Icons.search, color: Colors.white, size: 20)
            else
              Icon(Icons.info_outline, color: Colors.white.withOpacity(0.7), size: 20),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: canSearch ? Colors.white : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
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
    // Navigate to partner results screen, pass selected LatLng when available
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerResultsScreen(
          destination: selectedDestination,
          destinationLatLng: selectedLatLng,
        ),
      ),
    );
  }

  void _handleDestinationSelected() {
    if (selectedDestination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PartnerResultsScreen(
            destination: selectedDestination,
            destinationLatLng: selectedLatLng,
          ),
        ),
      );
    }
  }

  LatLng _getLatLngFromDestination(String destination) {
    final Map<String, LatLng> locationMap = {
      'UM Main Library': const LatLng(3.1235, 101.6545),
      'Student Center': const LatLng(3.1220, 101.6530),
      'Engineering Faculty': const LatLng(3.1240, 101.6555),
      'Sports Complex': const LatLng(3.1265, 101.6525),
    };
    return locationMap[destination] ?? const LatLng(3.1225, 101.6532);
  }

  // Campus-only search functionality
  void _onCampusSearchChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _filteredLocations = [];
        _showSearchResults = false;
      });
      return;
    }

    final query = value.toLowerCase();
    setState(() {
      _filteredLocations = campusLocations.where((location) {
        return location.name.toLowerCase().contains(query) ||
               location.category.toLowerCase().contains(query) ||
               location.building.toLowerCase().contains(query);
      }).toList();
      _showSearchResults = true;
    });
  }

  void _selectCampusLocation(CampusLocation location) {
    setState(() {
      selectedDestination = location.name;
      selectedLatLng = LatLng(location.lat, location.lng);
      _searchCtrl.text = location.name;
      _showSearchResults = false;
      _filteredLocations = [];
    });
  }

  void _clearSearch() {
    setState(() {
      _searchCtrl.clear();
      _filteredLocations = [];
      _showSearchResults = false;
    });
  }

  // Get locations to display based on current filters
  List<CampusLocation> _getDisplayLocations() {
    if (_showFavoritesOnly) {
      return campusLocations.where((location) => _favoriteLocations.contains(location.name)).toList();
    } else if (_showAllLocations) {
      return campusLocations;
    } else {
      return featuredLocations;
    }
  }

  // Favorites Management Functions
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('walk_favorite_locations');
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        setState(() {
          _favoriteLocations = favoritesList.cast<String>().toSet();
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(_favoriteLocations.toList());
      await prefs.setString('walk_favorite_locations', favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  void _toggleFavorite(String locationName) {
    setState(() {
      if (_favoriteLocations.contains(locationName)) {
        _favoriteLocations.remove(locationName);
        _showSnackBar('Removed from favorites: $locationName', Icons.star_border);
      } else {
        _favoriteLocations.add(locationName);
        _showSnackBar('Added to favorites: $locationName', Icons.star, Colors.amber);
      }
    });
    _saveFavorites();
  }

  void _showSnackBar(String message, IconData icon, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color ?? Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.deepPurple.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
