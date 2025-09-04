import 'package:flutter/material.dart';

void main() => runApp(SafeZoneXApp());

class SafeZoneXApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeZoneX',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SafeZoneX')),
      body: Center(child: Text('Welcome to SafeZoneX')),
    );
  }
}

