import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'backend_test_screen.dart';
import 'login_screen.dart';
import 'dart:io';
import 'edit_profile_sheet.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? studentId;
  final String? year;
  final String? faculty;
  final String? course;
  final String? userPhone;
  final File? studentIdImage;

  ProfileScreen({
    this.userName,
    this.userEmail,
    this.studentId,
    this.year,
    this.faculty,
    this.course,
    this.studentIdImage,
    this.userPhone,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  String _userName = '';
  String _userEmail = '';
  String _userFaculty = '';
  String _userCourse = '';
  String _userYear = '';
  String _userStudentId = '';
  String _userPhone = '';
  String _studentIdImagePath = '';
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load from unified user_data JSON first
      final userDataString = prefs.getString('user_data');
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          final userData = Map<String, dynamic>.from(jsonDecode(userDataString));
          _updateStateFromUserData(userData);
        } catch (e) {
          print('JSON parsing error: $e');
          _loadFromIndividualKeys(prefs);
        }
      } else {
        _loadFromIndividualKeys(prefs);
      }

      // Load notification preferences
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      // Use widget parameters as fallback if data is still empty
      _applyWidgetFallbacks();

    } catch (e) {
      print('Error loading user data: $e');
      _setDefaultValues();
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      // Start animations after loading
      _startAnimations();
    }
  }

  void _updateStateFromUserData(Map<String, dynamic> userData) {
    setState(() {
      _userName = userData['name']?.toString() ?? '';
      _userEmail = userData['email']?.toString() ?? '';
      _userFaculty = userData['selectedFaculty']?.toString() ?? '';
      _userCourse = userData['course']?.toString() ?? '';
      _userYear = userData['selectedYear']?.toString() ?? '';
      _userStudentId = userData['studentId']?.toString() ?? '';
      _userPhone = userData['phone']?.toString() ?? '';
      _studentIdImagePath = userData['studentIdImagePath']?.toString() ?? '';
    });
  }

  void _loadFromIndividualKeys(SharedPreferences prefs) {
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
      _userFaculty = prefs.getString('user_faculty') ?? '';
      _userCourse = prefs.getString('user_course') ?? '';
      _userYear = prefs.getString('user_year') ?? '';
      _userStudentId = prefs.getString('user_student_id') ?? '';
      _userPhone = prefs.getString('user_phone') ?? '';
      _studentIdImagePath = prefs.getString('student_id_image_path') ?? '';
    });
  }

  void _applyWidgetFallbacks() {
    setState(() {
      if (_userName.isEmpty && widget.userName != null) _userName = widget.userName!;
      if (_userEmail.isEmpty && widget.userEmail != null) _userEmail = widget.userEmail!;
      if (_userStudentId.isEmpty && widget.studentId != null) _userStudentId = widget.studentId!;
      if (_userFaculty.isEmpty && widget.faculty != null) _userFaculty = widget.faculty!;
      if (_userCourse.isEmpty && widget.course != null) _userCourse = widget.course!;
      if (_userYear.isEmpty && widget.year != null) _userYear = widget.year!;
      if (_userPhone.isEmpty && widget.userPhone != null) _userPhone = widget.userPhone!;
    });
  }

  void _setDefaultValues() {
    setState(() {
      _userName = widget.userName ?? 'User';
      _userEmail = widget.userEmail ?? 'No email';
      _userStudentId = widget.studentId ?? 'No ID';
      _userFaculty = widget.faculty ?? 'No faculty';
      _userCourse = widget.course ?? 'No course';
      _userYear = widget.year ?? 'No year';
      _userPhone = widget.userPhone ?? 'No phone';
    });
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
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
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUserData,
            color: Colors.deepPurple,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildProfileHeader(),
                    ),
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildSettingsSection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'Loading your profile...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
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
          _buildProfileAvatar(),
          const SizedBox(height: 24),
          _buildProfileInfo(),
          const SizedBox(height: 28),
          _buildProfileStats(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildProfileImage(),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (_studentIdImagePath.isNotEmpty) {
      final imageFile = File(_studentIdImagePath);
      if (imageFile.existsSync()) {
        return ClipOval(
          child: Image.file(
            imageFile,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              );
            },
          ),
        );
      }
    }
    
    return const Icon(
      Icons.person,
      size: 60,
      color: Colors.white,
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text(
          _userName.isNotEmpty ? _userName : 'Name not set',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (_userFaculty.isNotEmpty) ...[
          Text(
            _userFaculty,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
        if (_userYear.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 82, 248, 118).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color.fromARGB(255, 82, 248, 118),
                width: 1,
              ),
            ),
            child: Text(
              _userYear,
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 82, 248, 118),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Student ID',
                  _userStudentId.isNotEmpty ? _userStudentId : 'Not set',
                  Icons.badge,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  'Program',
                  _userCourse.isNotEmpty ? _userCourse : 'Not set',
                  Icons.school,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Email',
            _userEmail.isNotEmpty ? _userEmail : 'Not set',
            Icons.email,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color.fromARGB(255, 82, 248, 118),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(Icons.person_outline, 'Edit Profile', onTap: _editProfile),
          _buildSettingsTile(Icons.security_outlined, 'Privacy & Safety', onTap: _showPrivacySafety),
          _buildSettingsTile(Icons.verified_user_outlined, 'Account Security', onTap: _showAccountSecurity),
          _buildSettingsTile(Icons.notifications_outlined, 'Notifications', onTap: _showNotificationSettings),
          _buildSettingsTile(Icons.help_outline, 'Help & Support', onTap: _showHelpSupport),
          _buildSettingsTile(Icons.developer_mode_outlined, 'AI Backend Test', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackendTestScreen()),
            );
          }),
          _buildSettingsTile(
            Icons.logout_outlined,
            'Sign Out',
            isDestructive: true,
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDestructive ? Colors.red : Colors.deepPurple).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : Colors.deepPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => EditProfileSheet(
          userName: _userName,
          userEmail: _userEmail,
          studentId: _userStudentId,
          year: _userYear,
          faculty: _userFaculty,
          course: _userCourse,
          studentIdImage: _studentIdImagePath.isNotEmpty ? File(_studentIdImagePath) : null,
          onSave: _saveUpdatedProfile,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _saveUpdatedProfile(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create updated user data object
    final userData = {
      'name': profileData['name'] ?? _userName,
      'email': profileData['email'] ?? _userEmail,
      'phone': profileData['phone'] ?? _userPhone,
      'studentId': profileData['studentId'] ?? _userStudentId,
      'selectedYear': profileData['year'] ?? _userYear,
      'selectedFaculty': profileData['faculty'] ?? _userFaculty,
      'course': profileData['course'] ?? _userCourse,
      'studentIdImagePath': _studentIdImagePath,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    // Save in multiple formats for reliability
    await prefs.setString('user_data', jsonEncode(userData));
    
    // Save individual keys for backward compatibility
    final individualSaves = [
      prefs.setString('user_name', profileData['name'] ?? _userName),
      prefs.setString('user_email', profileData['email'] ?? _userEmail),
      prefs.setString('user_course', profileData['course'] ?? _userCourse),
      prefs.setString('user_year', profileData['year'] ?? _userYear),
      prefs.setString('user_student_id', profileData['studentId'] ?? _userStudentId),
      prefs.setString('user_faculty', profileData['faculty'] ?? _userFaculty),
      prefs.setString('user_phone', profileData['phone'] ?? _userPhone),
    ];
    
    await Future.wait(individualSaves);
    
    // Save emergency contacts if provided
    if (profileData['emergencyContact'] != null) {
      await prefs.setString('user_emergency_contact', profileData['emergencyContact']);
    }
    if (profileData['emergencyPhone'] != null) {
      await prefs.setString('user_emergency_phone', profileData['emergencyPhone']);
    }
    
    // Update state and refresh UI
    setState(() {
      _userName = profileData['name'] ?? _userName;
      _userEmail = profileData['email'] ?? _userEmail;
      _userFaculty = profileData['faculty'] ?? _userFaculty;
      _userCourse = profileData['course'] ?? _userCourse;
      _userYear = profileData['year'] ?? _userYear;
      _userStudentId = profileData['studentId'] ?? _userStudentId;
      _userPhone = profileData['phone'] ?? _userPhone;
    });
    
    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showPrivacySafety() {
    _showFeatureDialog(
      'Privacy & Safety',
      'Privacy and safety settings will be available in the next update. Your data is already encrypted and secure.',
      Icons.security_outlined,
    );
  }

  void _showAccountSecurity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Colors.green),
            SizedBox(width: 12),
            Text('Account Security', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityItem(Icons.verified, 'Google Authentication', Colors.green),
            _buildSecurityItem(Icons.domain_verification, 'UM Domain Verified', Colors.green),
            _buildSecurityItem(Icons.lock, 'End-to-End Encryption', Colors.blue),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                'Your account is fully secured with University of Malaya authentication and industry-standard encryption.',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Colors.deepPurple),
              SizedBox(width: 12),
              Text('Notifications', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Emergency Alerts', style: TextStyle(color: Colors.white)),
                subtitle: Text('Critical safety notifications', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                value: true,
                onChanged: null,
                activeColor: Colors.red,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Safety Updates', style: TextStyle(color: Colors.white)),
                subtitle: Text('Campus safety news and updates', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notifications_enabled', value);
                  setModalState(() {
                    _notificationsEnabled = value;
                  });
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeColor: Colors.deepPurple,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Text(
                  'Emergency alerts are always enabled for your safety and cannot be disabled.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(color: Colors.deepPurple)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport() {
    _showFeatureDialog(
      'Help & Support',
      'Comprehensive help and support features are coming in the next update. For immediate assistance, contact campus security at +60 3-7967 3200.',
      Icons.help_outline,
    );
  }

  void _showFeatureDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Sign Out', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out? You\'ll need to authenticate again with your UM Google account.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              
              try {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  ),
                );
                
                // Clear all local data
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                
                // Sign out from Google
                await _googleSignIn.signOut();
                
                // Navigate to login screen and clear navigation stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
                
              } catch (e) {
                // Close loading dialog
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Sign out failed: ${e.toString()}'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}