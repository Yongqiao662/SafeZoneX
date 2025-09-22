import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'backend_test_screen.dart';
import 'login_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? studentId;
  final String? year;
  final String? faculty;
  final String? course;
  final File? studentIdImage;

  ProfileScreen({
    this.userName,
    this.userEmail,
    this.studentId,
    this.year,
    this.faculty,
    this.course,
    this.studentIdImage,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
                      const SizedBox(height: 20),
                      Text(
                        widget.userName ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.faculty ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontFamily: 'Montserrat', // modern readable font
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.year ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 82, 248, 118),
                          fontFamily: 'RobotoMono', // distinct font for year
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 32,
                        runSpacing: 12,
                        children: [
                          _buildStatItem('Student ID', widget.studentId ?? '-', const Color.fromARGB(255, 82, 248, 118)),
                          _buildStatItem('Email', widget.userEmail ?? '-', const Color.fromARGB(255, 82, 248, 118)),
                          _buildStatItem('Program', widget.course ?? '-', const Color.fromARGB(255, 82, 248, 118)),
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
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: color,
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
          _buildSettingsTile(Icons.person, 'Edit Profile'),
          _buildSettingsTile(Icons.security, 'Privacy & Safety'),
          _buildSettingsTile(Icons.credit_card, 'Verify Credit Score'),
          _buildSettingsTile(Icons.notifications, 'Notifications'),
          _buildSettingsTile(Icons.help, 'Help & Support'),
          _buildSettingsTile(Icons.developer_mode, 'AI Backend Test', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackendTestScreen()),
            );
          }),
            _buildSettingsTile(
            Icons.logout,
            'Sign Out',
            isDestructive: true,
              onTap: () async {
                // Sign out logic
                final authService = AuthService();
                await authService.signOut();
                // Navigate to LoginScreen directly
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
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
        onTap: onTap ?? () {
          // Handle settings tap
        },
      ),
    );
  }
}