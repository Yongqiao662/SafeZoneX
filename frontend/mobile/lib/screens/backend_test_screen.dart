import 'package:flutter/material.dart';
import '../services/backend_api_service.dart';
import '../services/websocket_service.dart';
import 'dart:async';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({Key? key}) : super(key: key);

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  final BackendApiService _apiService = BackendApiService();
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _reportController = TextEditingController();
  
  String _connectionStatus = 'Disconnected';
  String _lastResult = 'No tests run yet';
  bool _isLoading = false;
  List<String> _notifications = [];
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeConnections();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnections() async {
    setState(() => _isLoading = true);
    
    // Test API connection
    await _testApiConnection();
    
    // Initialize WebSocket
    await _initializeWebSocket();
    
    setState(() => _isLoading = false);
  }

  Future<void> _testApiConnection() async {
    try {
      final result = await _apiService.checkServerStatus();
      setState(() {
        _connectionStatus = result['success'] ? 'Connected to AI Server' : 'Connection Failed';
        _lastResult = result['message'];
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection Error';
        _lastResult = 'Failed to connect: $e';
      });
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      // TODO: Replace with actual JWT token retrieval logic
      final token = 'your_jwt_token_here';
      _wsService.connect(token);
      _wsSubscription = _wsService.messageStream.listen((message) {
        setState(() {
          _notifications.insert(0, '${DateTime.now().toString().substring(11, 19)}: ${message['type']} - ${message.toString()}');
          if (_notifications.length > 10) _notifications.removeLast();
        });
      });
      setState(() => _connectionStatus += ' + WebSocket');
    } catch (e) {
      setState(() => _lastResult = 'WebSocket failed: $e');
    }
  }

  Future<void> _testMLStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiService.getMLStatus();
      setState(() {
        _lastResult = result['success'] 
          ? 'ML Status: ${result['status']['models']?.length ?? 0} models loaded'
          : 'ML Status Failed: ${result['message']}';
      });
    } catch (e) {
      setState(() => _lastResult = 'ML Status Error: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testAIAnalysis() async {
    final reportText = _reportController.text.trim();
    if (reportText.isEmpty) {
      setState(() => _lastResult = 'Please enter a report to test');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = '🧠 AI is analyzing your report... (this may take 30-60 seconds for first request)';
    });
    
    try {
      final result = await _apiService.submitSecurityReport(
        text: reportText,
        location: {'latitude': 40.7128, 'longitude': -74.0060}, // NYC coordinates
        metadata: {'test': true, 'source': 'flutter_test'},
      );
      
      if (result['success']) {
        final analysis = result['analysis'];
        final verification = analysis['verification'];
        final threat = analysis['threatAssessment'];
        
        setState(() {
          _lastResult = '''AI Analysis Results:
• Authentic: ${verification['isAuthentic']}
• Confidence: ${verification['confidence']?.toStringAsFixed(2)}
• Threat Level: ${threat?['threatLevel'] ?? 'None'}
• Action Required: ${analysis['actionRequired']}''';
        });
      } else {
        setState(() => _lastResult = 'AI Analysis Failed: ${result['message']}');
      }
    } catch (e) {
      setState(() => _lastResult = 'AI Analysis Error: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testMLTraining() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiService.trainMLModels();
      setState(() {
        _lastResult = result['success'] 
          ? 'ML Training: ${result['training']['reportAuthenticity']['accuracy'] * 100}% accuracy'
          : 'ML Training Failed: ${result['message']}';
      });
    } catch (e) {
      setState(() => _lastResult = 'ML Training Error: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _getActiveThreats() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiService.getActiveThreats();
      setState(() {
        _lastResult = result['success'] 
          ? 'Active Threats: ${result['threats']?.length ?? 0} found'
          : 'Threats Failed: ${result['message']}';
      });
    } catch (e) {
      setState(() => _lastResult = 'Threats Error: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Backend Test'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              color: _connectionStatus.contains('Connected') ? Colors.green[100] : Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_connectionStatus),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testApiConnection,
                      child: const Text('Test Connection'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Controls
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Report Input for AI Analysis
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Test AI Report Analysis',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _reportController,
                              decoration: const InputDecoration(
                                hintText: 'Enter security report text to test AI analysis...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _testAIAnalysis,
                              child: const Text('Analyze with AI'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Test Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testMLStatus,
                            child: const Text('ML Status'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testMLTraining,
                            child: const Text('Train ML'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _getActiveThreats,
                      child: const Text('Get Active Threats'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Results
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Result',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _lastResult,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Real-time Notifications
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Real-time Notifications',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 150,
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _notifications.isEmpty
                                  ? const Center(child: Text('No notifications yet'))
                                  : ListView.builder(
                                      itemCount: _notifications.length,
                                      itemBuilder: (context, index) {
                                        return Text(
                                          _notifications[index],
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
