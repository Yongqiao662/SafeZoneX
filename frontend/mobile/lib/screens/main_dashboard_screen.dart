import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'addfriend_screen.dart';
import 'walk_with_me.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'dart:io';

class MainDashboardScreen extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? studentId;
  final String? year;
  final String? faculty;
  final String? course;
  final File? studentIdImage;

  MainDashboardScreen({
    this.userName,
    this.userEmail,
    this.studentId,
    this.year,
    this.faculty,
    this.course,
    this.studentIdImage,
  });

  @override
  _MainDashboardScreenState createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    HomeScreen(),
    WalkWithMeHome(),
    FriendsScreen(),
    ReportsScreen(),
    ProfileScreen(
      userName: widget.userName,
      userEmail: widget.userEmail,
      studentId: widget.studentId,
      year: widget.year,
      faculty: widget.faculty,
      course: widget.course,
      studentIdImage: widget.studentIdImage,
    ),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildMainBottomNav(),
    );
  }



  Widget _buildMainBottomNav() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f0f1e),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.6),
            currentIndex: _selectedIndex,
            elevation: 0,
            enableFeedback: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            onTap: (index) {
              if (index != _selectedIndex) {
                // Add haptic feedback for smoother UX
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_rounded, 0),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.directions_walk_rounded, 1),
                label: 'Walk With Me',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.people_rounded, 2),
                label: 'Friends',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.report_problem_rounded, 3),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_rounded, 4),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        scale: isSelected ? 1.1 : 1.0,
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }
}