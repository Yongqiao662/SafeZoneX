import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'profile_screen.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main_dashboard_screen.dart';
import 'package:http/http.dart' as http;

// User Preferences Management Class
class UserPreferences {
  static const String _keyUserData = 'user_data';
  static const String _keyIsProfileComplete = 'is_profile_complete';

  // Save user profile data
  static Future<void> saveUserData({
    required String name,
    required String email,
    required String phone,
    required String studentId,
    required String selectedYear,
    required String selectedFaculty,
    String? course,
    String? studentIdImagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = {
      'name': name,
      'email': email,
      'phone': phone,
      'studentId': studentId,
      'selectedYear': selectedYear,
      'selectedFaculty': selectedFaculty,
      'course': course ?? '',
      'studentIdImagePath': studentIdImagePath ?? '',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_keyUserData, jsonEncode(userData));
    await prefs.setBool(_keyIsProfileComplete, true);
    
    // Also save individual keys for backward compatibility
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_student_id', studentId);
    await prefs.setString('user_year', selectedYear);
    await prefs.setString('user_faculty', selectedFaculty);
    await prefs.setString('user_course', course ?? '');
    if (studentIdImagePath != null && studentIdImagePath.isNotEmpty) {
      await prefs.setString('student_id_image_path', studentIdImagePath);
    }
  }

  // Load user profile data
  static Future<Map<String, String>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_keyUserData);
    
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      return userData.cast<String, String>();
    }
    return null;
  }

  // Check if profile is complete
  static Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsProfileComplete) ?? false;
  }

  // Clear user data (for logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);
    await prefs.setBool(_keyIsProfileComplete, false);
  }
}

class PersonalDetailsScreen extends StatefulWidget {
  final String name;
  final String email;

  const PersonalDetailsScreen({Key? key, required this.name, required this.email}) : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedFaculty = '';
  final List<String> _facultyOptions = [
    'Faculty of Arts and Social Sciences',
    'Faculty of Built Environment',
    'Faculty of Business and Economics',
    'Faculty of Computer Science and Information Technology',
    'Faculty of Creative Arts',
    'Faculty of Dentistry',
    'Faculty of Education',
    'Faculty of Engineering',
    'Faculty of Languages and Linguistics',
    'Faculty of Law',
    'Faculty of Medicine',
    'Faculty of Pharmacy',
    'Faculty of Science',
  ];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;
  
  bool _isLoading = false;
  File? _studentIdImage;
  String _selectedYear = '';
  
  final List<String> _studyYears = [
    'Year 1',
    'Year 2', 
    'Year 3',
    'Year 4',
    'Masters',
    'PhD'
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startEntryAnimation();
    _loadExistingData();
  }

  // Load existing user data
  void _loadExistingData() async {
    final savedData = await UserPreferences.getUserData();
    if (savedData != null) {
      setState(() {
        _nameController.text = savedData['name'] ?? widget.name;
        _emailController.text = savedData['email'] ?? widget.email;
        _phoneController.text = savedData['phone'] ?? '';
        _studentIdController.text = savedData['studentId'] ?? 
          (widget.email.length >= 8 ? widget.email.substring(0, 8) : widget.email);
        _selectedYear = savedData['selectedYear'] ?? '';
        _selectedFaculty = savedData['selectedFaculty'] ?? '';
        _courseController.text = savedData['course'] ?? '';
        
        // Load student ID image if available
        final imagePath = savedData['studentIdImagePath'];
        if (imagePath != null && imagePath.isNotEmpty) {
          _studentIdImage = File(imagePath);
        }
      });
    } else {
      // First time setup
      _nameController.text = widget.name;
      _emailController.text = widget.email;
      if (widget.email.length >= 8) {
        _studentIdController.text = widget.email.substring(0, 8);
      } else {
        _studentIdController.text = widget.email;
      }
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _buttonScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_buttonController);
  }

  void _startEntryAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
  }

  // Image picker function for Student ID
  void _pickStudentIdImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Student ID Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _simulateImagePick(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Camera', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _simulateImagePick(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _simulateImagePick(ImageSource source) {
    final picker = ImagePicker();
    picker.pickImage(source: source).then((pickedFile) {
      if (pickedFile != null) {
        setState(() {
          _studentIdImage = File(pickedFile.path);
        });
        _showSuccessSnackBar('Student ID image uploaded successfully');
      } else {
        _showErrorSnackBar('No image selected');
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Save data and navigate to MainDashboardScreen
  void _saveAndComplete() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedYear.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your year of study'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (_selectedFaculty.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your faculty'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Save to local storage
        await UserPreferences.saveUserData(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          studentId: _studentIdController.text.trim(),
          selectedYear: _selectedYear,
          selectedFaculty: _selectedFaculty,
          course: _courseController.text.trim(),
          studentIdImagePath: _studentIdImage?.path,
        );

        // Optional: Also send to your server
        await _sendToServer();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to MainDashboardScreen (passing data for immediate use)
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainDashboardScreen(),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Send data to your Node.js server
  Future<void> _sendToServer() async {
    try {
      final userData = {
        'userId': _studentIdController.text.trim(),
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'faculty': _selectedFaculty,
        'year': _selectedYear,
        'course': _courseController.text.trim(),
        'isVerified': false,
        'verificationScore': 0,
        'safetyRating': 5.0,
        'totalWalks': 0,
        'isActive': true,
        'joinedAt': DateTime.now().toIso8601String(),
        'lastSeen': DateTime.now().toIso8601String(),
      };

      // Replace with your actual server URL
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/user/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending to server: $e');
      // Don't throw - allow local save to succeed even if server fails
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _yearController.dispose();
    _courseController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    super.dispose();
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
              const SizedBox(height: 20),
              _buildBackButton(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildPersonalDetailsForm(),
                      const SizedBox(height: 32),
                      _buildCompleteButton(),
                      const SizedBox(height: 40),
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

  Widget _buildBackButton() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnim,
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
              Icons.person_add_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Complete Your Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in your details to complete registration',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsForm() {
    return SlideTransition(
      position: _slideAnim,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              hintText: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              icon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^\d{9,15}$').hasMatch(value)) {
                  return 'Enter a valid phone number (9-15 digits)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _studentIdController,
              hintText: 'Student ID',
              icon: Icons.badge_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your student ID';
                }
                if (value.length != 8) {
                  return 'Student ID must be 8 characters long';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            _buildYearDropdown(),
            const SizedBox(height: 20),
            _buildFacultyDropdown(),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _courseController,
              hintText: 'Course/Program (Optional)',
              icon: Icons.book_outlined,
            ),
            const SizedBox(height: 20),
            _buildStudentIdImagePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField2<String>(
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.school_outlined, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        hint: Text(
          'Select Year of Study',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        value: _selectedYear.isEmpty ? null : _selectedYear,
        items: _studyYears.map((year) => DropdownMenuItem(
          value: year,
          child: Text(year, style: const TextStyle(color: Colors.white)),
        )).toList(),
        onChanged: (value) {
          setState(() {
            _selectedYear = value ?? '';
          });
        },
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFacultyDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField2<String>(
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.account_balance_outlined, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        hint: Text(
          'Select Faculty',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        value: _selectedFaculty.isEmpty ? null : _selectedFaculty,
        items: _facultyOptions.map((faculty) => DropdownMenuItem(
          value: faculty,
          child: Text(faculty, style: const TextStyle(color: Colors.white)),
        )).toList(),
        onChanged: (value) {
          setState(() {
            _selectedFaculty = value ?? '';
          });
        },
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildStudentIdImagePicker() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _studentIdImage != null ? Colors.green : Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: _pickStudentIdImage,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _studentIdImage != null 
            ? Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_studentIdImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Student ID Photo Uploaded',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to change photo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white.withOpacity(0.7),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Student ID Photo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return ScaleTransition(
      scale: _buttonScaleAnim,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isLoading ? null : () {
              _buttonController.forward().then((_) {
                _buttonController.reverse();
              });
              _saveAndComplete();
            },
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Complete Registration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}