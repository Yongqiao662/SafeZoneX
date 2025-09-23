import 'package:flutter/material.dart';
import 'dart:io';

class EditProfileSheet extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String studentId;
  final String year;
  final String faculty;
  final String course;
  final File? studentIdImage;
  final Function(Map<String, String>) onSave;
  final ScrollController scrollController;

  const EditProfileSheet({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.studentId,
    required this.year,
    required this.faculty,
    required this.course,
    required this.studentIdImage,
    required this.onSave,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController nameController;
  late TextEditingController studentIdController;
  late TextEditingController phoneController;
  late TextEditingController emergencyContactController;
  late TextEditingController emergencyPhoneController;
  
  String selectedFaculty = '';
  String selectedYear = '';
  String selectedCourse = '';
  
  final _formKey = GlobalKey<FormState>();
  
  // Faculty options
  final List<String> facultyOptions = [
    'Faculty of Arts and Social Sciences',
    'Faculty of Business and Economics',
    'Faculty of Computer Science and Information Technology',
    'Faculty of Dentistry',
    'Faculty of Education',
    'Faculty of Engineering',
    'Faculty of Languages and Linguistics',
    'Faculty of Law',
    'Faculty of Medicine',
    'Faculty of Science',
    'Faculty of Built Environment',
    'Faculty of Creative Arts',
    'Institute of Graduate Studies',
  ];
  
  // Year options
  final List<String> yearOptions = [
    'Year 1',
    'Year 2', 
    'Year 3',
    'Year 4',
    'Year 5',
    'Masters',
    'PhD',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userName);
    studentIdController = TextEditingController(text: widget.studentId);
    phoneController = TextEditingController();
    emergencyContactController = TextEditingController();
    emergencyPhoneController = TextEditingController();
    
    selectedFaculty = widget.faculty;
    selectedYear = widget.year;
    selectedCourse = widget.course;
  }

  @override
  void dispose() {
    nameController.dispose();
    studentIdController.dispose();
    phoneController.dispose();
    emergencyContactController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
          ],
        ),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Profile Image Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: widget.studentIdImage != null
                          ? ClipOval(
                              child: Image.file(
                                widget.studentIdImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name Field
                _buildTextField(
                  controller: nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email Field (Read-only)
                _buildTextField(
                  controller: TextEditingController(text: widget.userEmail),
                  label: 'Email',
                  icon: Icons.email,
                  enabled: false,
                  helperText: 'Email cannot be changed (UM Google Account)',
                ),
                const SizedBox(height: 16),
                
                // Student ID Field
                _buildTextField(
                  controller: studentIdController,
                  label: 'Student ID',
                  icon: Icons.badge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Student ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Faculty Dropdown
                _buildDropdownField(
                  value: selectedFaculty,
                  label: 'Faculty',
                  icon: Icons.school,
                  items: facultyOptions,
                  onChanged: (value) {
                    setState(() {
                      selectedFaculty = value ?? '';
                      selectedCourse = ''; // Reset course when faculty changes
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Course Field
                _buildTextField(
                  controller: TextEditingController(text: selectedCourse),
                  label: 'Course/Program',
                  icon: Icons.book,
                  onChanged: (value) {
                    selectedCourse = value;
                  },
                ),
                const SizedBox(height: 16),
                
                // Year Dropdown
                _buildDropdownField(
                  value: selectedYear,
                  label: 'Year of Study',
                  icon: Icons.calendar_today,
                  items: yearOptions,
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                _buildTextField(
                  controller: phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                
                // Emergency Contact Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Emergency Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: emergencyContactController,
                        label: 'Emergency Contact Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: emergencyPhoneController,
                        label: 'Emergency Contact Phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
    String? helperText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
        ),
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
        ),
        filled: true,
        fillColor: enabled 
          ? Colors.white.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
        ),
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      dropdownColor: const Color(0xFF16213e),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      selectedItemBuilder: (BuildContext context) {
        return items.map((String item) {
          return Container(
            alignment: Alignment.centerLeft,
            child: Text(
              item,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Container(
            width: double.infinity,
            child: Text(
              item,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave({
        'name': nameController.text.trim(),
        'studentId': studentIdController.text.trim(),
        'faculty': selectedFaculty,
        'course': selectedCourse,
        'year': selectedYear,
        'phone': phoneController.text.trim(),
        'emergencyContact': emergencyContactController.text.trim(),
        'emergencyPhone': emergencyPhoneController.text.trim(),
      });
      Navigator.pop(context);
    }
  }
}