import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import 'active_walk_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  final UserProfile partner;

  const FaceVerificationScreen({
    Key? key,
    required this.partner,
  }) : super(key: key);

  @override
  _FaceVerificationScreenState createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isCapturing = false;
  bool _isVerifying = false;
  bool _verificationComplete = false;
  bool _verificationSuccess = false;
  String _verificationMessage = '';
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _captureAndVerifyFace() async {
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isCapturing = false;
          _isVerifying = true;
        });

        // Simulate face verification process
        await _performFaceVerification(image);
      } else {
        setState(() {
          _isCapturing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showErrorDialog('Failed to capture image. Please ensure camera permissions are granted.');
    }
  }

  Future<void> _performFaceVerification(XFile imageFile) async {
    // Simulate AI face verification process
    await Future.delayed(const Duration(seconds: 3));

    // Mock verification logic - in real implementation, this would:
    // 1. Extract face features from captured image
    // 2. Compare with partner's profile photo
    // 3. Use ML model for face matching (TensorFlow Lite, MLKit)
    // 4. Return confidence score

    // For demo purposes, simulate 85% success rate
    bool success = DateTime.now().millisecond % 100 > 15;
    
    setState(() {
      _isVerifying = false;
      _verificationComplete = true;
      _verificationSuccess = success;
      _verificationMessage = success 
        ? 'Face verification successful! Identity confirmed.'
        : 'Face verification failed. Please ensure good lighting and try again.';
    });

    if (success) {
      // Auto-proceed to active walk after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _onVerificationSuccess();
        }
      });
    }
  }

  void _onVerificationSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWalkScreen(
          partner: UserProfile(
            id: widget.partner.id,
            name: widget.partner.name,
            profilePicture: widget.partner.profilePicture,
            rating: widget.partner.rating,
            walkCount: widget.partner.walkCount,  // Fixed: was totalWalks
            location: widget.partner.location,
            estimatedMinutes: widget.partner.estimatedMinutes,
            isVerified: widget.partner.isVerified,
            department: widget.partner.department,
            creditScore: widget.partner.creditScore,
          ),
        ),
      ),
    );
  }

  void _retryVerification() {
    setState(() {
      _verificationComplete = false;
      _verificationSuccess = false;
      _verificationMessage = '';
      _capturedImage = null;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              // Title Section - Matching other screens style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple, // Single purple color to match walk request
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Verify Walk Partner',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Partner Info Header
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF16213e),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.deepPurple,
                      child: widget.partner.profilePicture?.startsWith('assets/') == true
                        ? ClipOval(child: Image.asset(widget.partner.profilePicture!, fit: BoxFit.cover))
                        : Text(
                            widget.partner.profilePicture ?? widget.partner.name[0],
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verifying: ${widget.partner.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Safety verification required before walk',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.partner.isVerified ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.partner.isVerified ? 'VERIFIED' : 'PENDING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Column(
                  children: [
                    // Camera Preview Placeholder
                    Expanded(
                      flex: 2, // Reduced from 3 to 2 to give more space for bottom content
                      child: Container(
                        width: double.infinity,
                        child: _buildCameraView(),
                      ),
                    ),

                    // Verification Status
                    if (_verificationComplete) _buildVerificationResult(),

                    // Instructions and Controls
                    Flexible( // Changed from Expanded to Flexible to prevent overflow
                      child: Container(
                        padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Add this to minimize space usage
                          children: [
                            if (!_verificationComplete) ...[
                              const Text(
                                'Take a photo to verify your identity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15, // Reduced from 16 to 15
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4), // Reduced from 6 to 4
                              Text(
                                'This helps ensure safety for both walking partners',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13, // Reduced from 14 to 13
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12), // Reduced from 16 to 12
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Capture Button
                                  GestureDetector(
                                    onTap: _isCapturing || _isVerifying ? null : _captureAndVerifyFace,
                                    child: Container(
                                      width: 70, // Reduced from 80 to 70
                                      height: 70, // Reduced from 80 to 70
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isCapturing || _isVerifying 
                                          ? Colors.grey 
                                          : Colors.deepPurple,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2, // Reduced from 3 to 2
                                        ),
                                      ),
                                      child: Icon(
                                        _isCapturing 
                                          ? Icons.hourglass_empty 
                                          : Icons.camera_alt,
                                        size: 25, // Reduced from 30 to 25
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (_verificationComplete && !_verificationSuccess) ...[
                              ElevatedButton(
                                onPressed: _retryVerification,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  minimumSize: const Size(180, 45), // Reduced from Size(200, 50)
                                ),
                                child: const Text('Try Again'),
                              ),
                              const SizedBox(height: 6), // Reduced from 8 to 6
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancel Walk',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],

                            if (_isVerifying)
                              Column( // Removed const
                                mainAxisSize: MainAxisSize.min, // Add this to minimize space
                                children: [
                                  const CircularProgressIndicator(color: Colors.deepPurple),
                                  const SizedBox(height: 6), // Reduced from 8 to 6
                                  const Text(
                                    'Verifying identity...',
                                    style: TextStyle(color: Colors.white, fontSize: 14), // Reduced font size
                                  ),
                                ],
                              ),
                          ],
                        ),
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

  Widget _buildCameraView() {
    return Container(
      margin: const EdgeInsets.all(16), // Reduced from 20 to 16
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _verificationComplete
            ? (_verificationSuccess ? Colors.green : Colors.red)
            : Colors.deepPurple,
          width: 3,
        ),
      ),
      child: _capturedImage != null 
        ? ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 80, // Reduced from 100 to 80
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16), // Reduced from 20 to 16
              Text(
                'Face Verification Required',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the camera button below to take a selfie',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
    );
  }

  Widget _buildVerificationResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: _verificationSuccess ? Colors.green[700] : Colors.red[700],
      child: Row(
        children: [
          Icon(
            _verificationSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _verificationMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_verificationSuccess)
            const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildPartnerImage() {
    return CircleAvatar(
      radius: 50,
      backgroundImage: widget.partner.profilePicture != null
          ? (widget.partner.profilePicture!.startsWith('assets/')
              ? AssetImage(widget.partner.profilePicture!) as ImageProvider
              : NetworkImage(widget.partner.profilePicture!) as ImageProvider)
          : null,
      child: widget.partner.profilePicture == null
          ? Text(widget.partner.name[0], style: const TextStyle(fontSize: 40))
          : null,
    );
  }
}

// Custom painter for face detection guidelines
class FaceGuidelinePainter extends CustomPainter {
  final Color color;

  FaceGuidelinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final ovalWidth = 250.0;
    final ovalHeight = 300.0;

    // Draw corner guides
    final cornerLength = 30.0;
    final cornerOffset = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(centerX - ovalWidth/2 - cornerOffset, centerY - ovalHeight/2),
      Offset(centerX - ovalWidth/2 - cornerOffset + cornerLength, centerY - ovalHeight/2),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - ovalWidth/2 - cornerOffset, centerY - ovalHeight/2),
      Offset(centerX - ovalWidth/2 - cornerOffset, centerY - ovalHeight/2 + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(centerX + ovalWidth/2 + cornerOffset, centerY - ovalHeight/2),
      Offset(centerX + ovalWidth/2 + cornerOffset - cornerLength, centerY - ovalHeight/2),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + ovalWidth/2 + cornerOffset, centerY - ovalHeight/2),
      Offset(centerX + ovalWidth/2 + cornerOffset, centerY - ovalHeight/2 + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(centerX - ovalWidth/2 - cornerOffset, centerY + ovalHeight/2),
      Offset(centerX - ovalWidth/2 - cornerOffset + cornerLength, centerY + ovalHeight/2),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - ovalWidth/2 - cornerOffset, centerY + ovalHeight/2),
      Offset(centerX - ovalWidth/2 - cornerOffset, centerY + ovalHeight/2 - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(centerX + ovalWidth/2 + cornerOffset, centerY + ovalHeight/2),
      Offset(centerX + ovalWidth/2 + cornerOffset - cornerLength, centerY + ovalHeight/2),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + ovalWidth/2 + cornerOffset, centerY + ovalHeight/2),
      Offset(centerX + ovalWidth/2 + cornerOffset, centerY + ovalHeight/2 - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}