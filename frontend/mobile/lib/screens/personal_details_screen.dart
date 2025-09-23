import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'main_dashboard_screen.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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
    // Autofill name and email
    _nameController.text = widget.name;
    _emailController.text = widget.email;
    // Autofill student ID as first 8 characters of email
    if (widget.email.length >= 8) {
      _studentIdController.text = widget.email.substring(0, 8);
    } else {
      _studentIdController.text = widget.email;
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
                // Basic email validation
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                  return 'Please enter a valid email';
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
                  return 'ID must be 8 characters long';
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
              hintText: 'Course/Program',
              icon: Icons.school_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your course';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildStudentIdUpload(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
        child: DropdownButtonFormField<String>(
          value: _selectedYear.isEmpty ? null : _selectedYear,
          hint: Text(
          'Year of Study',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: Colors.white.withOpacity(0.7),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
          ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  ),
  dropdownColor: const Color(0xFF16213e),
  style: TextStyle(
    color: _selectedYear.isEmpty
        ? Colors.white.withOpacity(0.6)
        : Colors.white,
    fontSize: 16,
  ),
  icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
  items: _studyYears.map((String year) {
    return DropdownMenuItem<String>(
      value: year,
      child: Text(year, style: const TextStyle(color: Colors.white)),
    );
  }).toList(),
  onChanged: (String? newValue) {
    setState(() {
      _selectedYear = newValue ?? '';
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please select your year of study';
    }
    return null;
  },
),
    );
  }

  Widget _buildFacultyDropdown() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: DropdownButtonFormField2<String>(
      alignment: Alignment.centerLeft,
      value: _selectedFaculty.isEmpty ? null : _selectedFaculty,
      decoration: InputDecoration(
        hintText: 'Faculty',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 16,
          // Removed height property to fix alignment
        ),
        prefixIcon: Icon(
          Icons.account_balance_outlined,
          color: Colors.white.withOpacity(0.7),
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        contentPadding: const EdgeInsets.only(
          left: 12,
          right: 18,
          top: 16,
          bottom: 16,
        ),
        // Add this to ensure proper alignment
        isDense: false,
      ),
      dropdownStyleData: DropdownStyleData(
        direction: DropdownDirection.textDirection,
        maxHeight: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        height: 1.2, // Proper line height for text
      ),
      iconStyleData: IconStyleData(
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      items: _facultyOptions.map((String faculty) {
        return DropdownMenuItem<String>(
          value: faculty,
          child: SizedBox(
            width: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                faculty,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedFaculty = newValue ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your faculty';
        }
        return null;
      },
    ),
  );
}



  Widget _buildStudentIdUpload() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _studentIdImage != null 
              ? Colors.green 
              : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _studentIdImage != null 
                ? Icons.check_circle_outline 
                : Icons.upload_file_outlined,
              color: _studentIdImage != null 
                ? Colors.green 
                : Colors.white.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              _studentIdImage != null 
                ? 'Student ID Uploaded' 
                : 'Upload Student ID',
              style: TextStyle(
                color: _studentIdImage != null 
                  ? Colors.green 
                  : Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _studentIdImage != null 
                ? 'Tap to change image' 
                : 'Take a photo or select from gallery',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickStudentIdImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _studentIdImage != null ? 'Change Image' : 'Choose Image',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SlideTransition(
      position: _slideAnim,
      child: ScaleTransition(
        scale: _buttonScaleAnim,
        child: GestureDetector(
          onTapDown: (_) => _buttonController.forward(),
          onTapUp: (_) => _buttonController.reverse(),
          onTapCancel: () => _buttonController.reverse(),
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
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _completeRegistration(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Complete Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

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
                      _simulateImagePick('camera');
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
                      _simulateImagePick('gallery');
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

  void _simulateImagePick(String source) {
    // Use image_picker to pick image from gallery
    final picker = ImagePicker();
    picker.pickImage(source: ImageSource.gallery).then((pickedFile) {
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

  Future<void> _completeRegistration(BuildContext context) async {
    if (_isLoading) return;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_studentIdImage == null) {
      _showErrorSnackBar('Please upload your student ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate registration process
      await Future.delayed(const Duration(seconds: 3));
      
      _showSuccessSnackBar('Registration completed successfully!');
      await _exitAnimation();
      
      // Navigate to main dashboard, passing user details
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainDashboardScreen(
            userName: _nameController.text,
            userEmail: _emailController.text,
            studentId: _studentIdController.text,
            year: _selectedYear,
            faculty: _selectedFaculty,
            course: _courseController.text,
            studentIdImage: _studentIdImage,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Registration failed: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exitAnimation() async {
    await Future.wait([
      _slideController.reverse(),
      _fadeController.reverse(),
    ]);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}