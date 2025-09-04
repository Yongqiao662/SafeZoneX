import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(SafeZoneXWebApp());
}

class SafeZoneXWebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeZoneX - Emergency Monitor',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0f0f1e),
        cardTheme: const CardThemeData(
          color: Color(0xFF1a1a2e),
          elevation: 8,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213e),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
