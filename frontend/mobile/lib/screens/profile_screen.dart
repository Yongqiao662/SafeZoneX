import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'backend_test_screen.dart';
import 'login_screen.dart';

class EditProfileSheet extends StatefulWidget {
  final String userName;
  final String userEmail;
  final Function(Map<String, String>) onSave;

  const EditProfileSheet({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditProfileSheetState createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _studentIdController;
  late TextEditingController _courseController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;
  
  String _selectedFaculty = '';
  String _selectedYear = '';

  final List<String> _faculties = [
    'Faculty of Arts and Social Sciences',
    'Faculty of Science',
    'Faculty of Engineering',
    'Faculty of Medicine',
    'Faculty of Economics and Administration',
    'Faculty of Law',
    'Faculty of Computer Science and Information Technology',
    'Faculty of Business and Accountancy',
    'Faculty of Education',
    'Faculty of Dentistry',
    'Faculty of Languages and Linguistics',
    'Faculty of Built Environment',
    'Faculty of Pharmacy',
  ];

  final List<String> _years = ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5', 'Year 6'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _studentIdController = TextEditingController();
    _courseController = TextEditingController();
    _phoneController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFaculty = prefs.getString('user_faculty') ?? '';
      _selectedYear = prefs.getString('user_year') ?? '';
      _studentIdController.text = prefs.getString('user_student_id') ?? '';
      _courseController.text = prefs.getString('user_course') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _emergencyContactController.text = prefs.getString('user_emergency_contact') ?? '';
      _emergencyPhoneController.text = prefs.getString('user_emergency_phone') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Email (Read-only)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'University Email',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userEmail,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Linked to your UM Google account (cannot be changed)',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Display Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Display Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  
                  // Student ID
                  _buildTextField(
                    controller: _studentIdController,
                    label: 'Student ID (numbers only)',
                    icon: Icons.badge,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Faculty
                  _buildDropdown(
                    label: 'Faculty',
                    value: _selectedFaculty,
                    items: _faculties,
                    onChanged: (value) {
                      setState(() {
                        _selectedFaculty = value ?? '';
                      });
                    },
                    icon: Icons.school,
                  ),
                  const SizedBox(height: 16),
                  
                  // Course
                  _buildTextField(
                    controller: _courseController,
                    label: 'Course/Program',
                    icon: Icons.book,
                  ),
                  const SizedBox(height: 16),
                  
                  // Year
                  _buildDropdown(
                    label: 'Current Year',
                    value: _selectedYear,
                    items: _years,
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value ?? '';
                      });
                    },
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  
                  // Emergency Contact Section
                  Container(
                    width: double.infinity,
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
                            Icon(Icons.emergency, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Emergency Contact',
                                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emergencyContactController,
                          label: 'Emergency Contact Name',
                          icon: Icons.person_outline,
                          borderColor: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emergencyPhoneController,
                          label: 'Emergency Contact Phone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          borderColor: Colors.red.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
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
                        'Save Profile',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Color? borderColor,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.deepPurple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      dropdownColor: const Color(0xFF1a1a2e),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      isExpanded: true,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Container(
            width: double.infinity,
            child: Text(
              item,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _saveProfile() {
    final profileData = {
      'name': _nameController.text.trim(),
      'studentId': _studentIdController.text.trim(),
      'faculty': _selectedFaculty,
      'course': _courseController.text.trim(),
      'year': _selectedYear,
      'phone': _phoneController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim(),
      'emergencyPhone': _emergencyPhoneController.text.trim(),
    };
    
    widget.onSave(profileData);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _courseController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String _userFaculty = '';
  String _userCourse = '';
  String _userYear = '';
  String _userStudentId = '';
  bool _notificationsEnabled = true;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'UM Student';
      _userEmail = prefs.getString('user_email') ?? 'student@siswa.um.edu.my';
      _userFaculty = prefs.getString('user_faculty') ?? '';
      _userCourse = prefs.getString('user_course') ?? '';
      _userYear = prefs.getString('user_year') ?? '';
      _userStudentId = prefs.getString('user_student_id') ?? '';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userStudentId.isNotEmpty ? _userStudentId : _userEmail.split('@')[0],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_userYear.isNotEmpty || _userCourse.isNotEmpty || _userFaculty.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        if (_userYear.isNotEmpty && _userCourse.isNotEmpty)
                          Text(
                            '$_userYear • $_userCourse',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (_userFaculty.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _userFaculty,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ] else
                        Text(
                          'University of Malaya Student',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Safety Score', '95', Colors.green),
                          _buildStatItem('Reports', '3', Colors.blue),
                          _buildStatItem('Alerts', '12', Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSettingsSection(),
              ],
            ),
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
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(Icons.person, 'Edit Profile', onTap: _editProfile),
          _buildSettingsTile(Icons.security, 'Privacy & Safety', onTap: _showPrivacySafety),
          _buildSettingsTile(Icons.verified_user, 'Account Security', onTap: _showAccountSecurity),
          _buildSettingsTile(Icons.notifications, 'Notifications', onTap: _showNotificationSettings),
          _buildSettingsTile(Icons.help, 'Help & Support', onTap: _showHelpSupport),
          _buildSettingsTile(Icons.developer_mode, 'AI Backend Test', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackendTestScreen()),
            );
          }),
          _buildSettingsTile(Icons.logout, 'Sign Out', isDestructive: true, onTap: _signOut),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.white.withOpacity(0.8),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.5),
        ),
        onTap: onTap,
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
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => EditProfileSheet(
          userName: _userName,
          userEmail: _userEmail,
          onSave: (profileData) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_name', profileData['name'] ?? _userName);
            await prefs.setString('user_course', profileData['course'] ?? '');
            await prefs.setString('user_year', profileData['year'] ?? '');
            await prefs.setString('user_student_id', profileData['studentId'] ?? '');
            await prefs.setString('user_faculty', profileData['faculty'] ?? '');
            await prefs.setString('user_phone', profileData['phone'] ?? '');
            await prefs.setString('user_emergency_contact', profileData['emergencyContact'] ?? '');
            await prefs.setString('user_emergency_phone', profileData['emergencyPhone'] ?? '');
            
            setState(() {
              _userName = profileData['name'] ?? _userName;
              _userFaculty = profileData['faculty'] ?? '';
              _userCourse = profileData['course'] ?? '';
              _userYear = profileData['year'] ?? '';
              _userStudentId = profileData['studentId'] ?? '';
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPrivacySafety() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                'Privacy & Safety',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildPrivacyTile('Location Privacy', 'Control who can see your location', Icons.location_on),
                    _buildPrivacyTile('Emergency Contacts', 'Manage your emergency contact list', Icons.emergency),
                    _buildPrivacyTile('Data Sharing', 'Control what data is shared with authorities', Icons.share),
                    _buildPrivacyTile('Anonymous Reporting', 'Report incidents anonymously', Icons.report),
                    _buildPrivacyTile('Block List', 'Manage blocked users', Icons.block),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Safety Matters',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SafeZoneX is designed with privacy-first principles. Your location data is encrypted, and you have full control over what information is shared.',
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7))),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
      onTap: () {
        switch (title) {
          case 'Location Privacy':
            _showLocationPrivacy();
            break;
          case 'Emergency Contacts':
            _showEmergencyContactsManager();
            break;
          case 'Data Sharing':
            _showDataSharingSettings();
            break;
          case 'Anonymous Reporting':
            _showAnonymousReporting();
            break;
          case 'Block List':
            _showBlockListManager();
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title settings coming soon')),
            );
        }
      },
    );
  }

  void _showLocationPrivacy() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool shareLocationWithSecurity = true;
          bool shareLocationWithFriends = false;
          bool shareLocationDuringEmergency = true;
          
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text('Location Privacy', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Share with Campus Security', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Allow security to see your location', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  value: shareLocationWithSecurity,
                  onChanged: null, // Always enabled for safety
                  activeColor: Colors.green,
                ),
                SwitchListTile(
                  title: const Text('Share with Friends', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Let trusted friends see your location', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  value: shareLocationWithFriends,
                  onChanged: (value) {
                    setModalState(() {
                      shareLocationWithFriends = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                SwitchListTile(
                  title: const Text('Emergency Location Sharing', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Auto-share location during emergencies', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  value: shareLocationDuringEmergency,
                  onChanged: null, // Always enabled for safety
                  activeColor: Colors.red,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Campus security and emergency location sharing cannot be disabled for your safety.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEmergencyContactsManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Row(
              children: [
                Icon(Icons.emergency, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildEmergencyContactCard('Campus Security', '+60 3-7967 3200', Icons.security, true),
                  _buildEmergencyContactCard('Personal Emergency Contact', _getStoredEmergencyContact(), Icons.person, false),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editProfile();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Emergency Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        const Text(
                          'Emergency Protocol',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'In case of emergency, your location and contact information will be automatically shared with campus security and your designated emergency contacts.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(String name, String contact, IconData icon, bool isSystem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSystem ? Colors.blue : Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  contact.isEmpty ? 'Not set' : contact,
                  style: TextStyle(
                    color: contact.isEmpty ? Colors.orange : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!isSystem)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                _editProfile();
              },
              icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            ),
        ],
      ),
    );
  }

  String _getStoredEmergencyContact() {
    // This would load from SharedPreferences in real implementation
    return 'Emergency contact not set';
  }

  void _showDataSharingSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool shareWithSecurity = true;
          bool shareWithMedical = false;
          bool shareWithParents = false;
          
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: const Row(
              children: [
                Icon(Icons.share, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text('Data Sharing', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Campus Security', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Share safety data with security', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    value: shareWithSecurity,
                    onChanged: null, // Always enabled
                    activeColor: Colors.green,
                  ),
                  SwitchListTile(
                    title: const Text('Medical Services', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Share health data during emergencies', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    value: shareWithMedical,
                    onChanged: (value) {
                      setModalState(() {
                        shareWithMedical = value;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  SwitchListTile(
                    title: const Text('Emergency Contacts', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Share location with emergency contacts', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    value: shareWithParents,
                    onChanged: (value) {
                      setModalState(() {
                        shareWithParents = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data Protection',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All shared data is encrypted and used only for safety purposes. You can revoke permissions at any time.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Settings', style: TextStyle(color: Colors.orange)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAnonymousReporting() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Row(
              children: [
                Icon(Icons.report, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Anonymous Reporting',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Safely & Anonymously',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your identity is protected when reporting incidents. All reports are encrypted and processed securely.',
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Report Categories:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    _buildReportCategory('Safety Hazard', 'Unsafe areas, broken equipment, poor lighting', Icons.warning),
                    _buildReportCategory('Harassment', 'Any form of harassment or discrimination', Icons.person_off),
                    _buildReportCategory('Suspicious Activity', 'Unusual or concerning behavior', Icons.visibility),
                    _buildReportCategory('Emergency', 'Immediate safety concerns requiring urgent response', Icons.emergency),
                    _buildReportCategory('Other', 'Any other safety-related concerns', Icons.more_horiz),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showReportForm();
                        },
                        icon: const Icon(Icons.report),
                        label: const Text('Submit Anonymous Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCategory(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }

  void _showReportForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Anonymous Report', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Report submission feature will be implemented in the next version. For immediate assistance, please contact campus security directly.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEmergencyContacts();
            },
            child: const Text('Emergency Contacts', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBlockListManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  'Block List',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.block, color: Colors.grey, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No Blocked Users',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Users you block will not be able to see your location or contact you through the app.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to Block Users',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Go to a user\'s profile and tap "Block User"\n• Report inappropriate behavior to automatically block\n• Blocked users can be unblocked at any time',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSecurity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Account Security', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Google Authentication', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('UM Domain Verified', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.security, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Encrypted Data', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                'Your account is secured with University of Malaya Google authentication. No additional passwords are required.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.deepPurple)),
          ),
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
          title: const Text('Notification Settings', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Emergency Alerts', style: TextStyle(color: Colors.white)),
                subtitle: Text('Critical safety notifications', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                value: true,
                onChanged: null, // Always enabled for safety
                activeColor: Colors.red,
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
              ),
              const SizedBox(height: 16),
              Text(
                'Emergency alerts cannot be disabled for your safety.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.deepPurple)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildHelpTile('Emergency Hotline', 'Call campus security immediately', Icons.phone, () {
                    _showEmergencyContacts();
                  }),
                  _buildHelpTile('FAQ', 'Frequently asked questions', Icons.help_outline, null),
                  _buildHelpTile('Report Bug', 'Report technical issues', Icons.bug_report, null),
                  _buildHelpTile('Feature Request', 'Suggest new features', Icons.lightbulb_outline, null),
                  _buildHelpTile('Contact Support', 'Get help from our team', Icons.support_agent, null),
                  const SizedBox(height: 20),
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
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'In Case of Emergency',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'For immediate assistance, use the emergency button on the home screen or call campus security directly.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7))),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon')),
        );
      },
    );
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Emergency Contacts', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmergencyContact('UM Campus Security', '+60 3-7967 3200'),
            _buildEmergencyContact('Police Emergency', '999'),
            _buildEmergencyContact('Medical Emergency', '999'),
            _buildEmergencyContact('Fire Department', '994'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String title, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(number, style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out? You\'ll need to sign in again with your UM Google account.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Clear local storage
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                
                // Sign out from Google
                await _googleSignIn.signOut();
                
                // Navigate to login screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign out failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}