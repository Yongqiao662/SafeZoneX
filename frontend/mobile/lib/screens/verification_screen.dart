import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'personal_details_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  
  const VerificationScreen({Key? key, required this.email, required this.name}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> 
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;
  
  bool _isLoading = false;
  bool _isResending = false;
  String _verificationCode = '';
  String? _correctCode; // Will be fetched from backend
  
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startEntryAnimation();
    _startResendTimer();
    _sendVerificationCode(); // Send code on screen load
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

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
          if (_resendTimer <= 0) {
            _canResend = true;
          }
        });
      }
      return _resendTimer > 0 && mounted;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     MediaQuery.of(context).padding.bottom,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildBackButton(),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 60),
                        _buildVerificationForm(),
                        const SizedBox(height: 32),
                        _buildVerifyButton(),
                        const SizedBox(height: 24),
                        _buildResendSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return FadeTransition(
      opacity: _fadeAnim,
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
              Icons.mark_email_read_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verify Your Email',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter the 6-digit verification code sent to:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.purpleAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm() {
    return SlideTransition(
      position: _slideAnim,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildCodeField(index)),
            ),
            const SizedBox(height: 20),
            if (_correctCode != null) // Only show in development
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dev Mode: Code is $_correctCode',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildCodeField(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty 
            ? Colors.purpleAccent 
            : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          _updateVerificationCode();
        },
      ),
    );
  }

  void _updateVerificationCode() {
    _verificationCode = _controllers.map((controller) => controller.text).join();
    setState(() {});
  }

  Widget _buildVerifyButton() {
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
              gradient: LinearGradient(
                colors: _verificationCode.length == 6
                  ? [Colors.deepPurple, Colors.purpleAccent]
                  : [Colors.grey.shade600, Colors.grey.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _verificationCode.length == 6
                ? [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
            ),
            child: ElevatedButton(
              onPressed: _isLoading || _verificationCode.length != 6 
                ? null 
                : () => _verifyCode(context),
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
                      'Verify Code',
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

  Widget _buildResendSection() {
    return SlideTransition(
      position: _slideAnim,
      child: Column(
        children: [
          Text(
            _canResend 
              ? "Didn't receive the code?"
              : "Resend code in ${_resendTimer}s",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          if (_canResend) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isResending ? null : _resendCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isResending) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isResending ? 'Sending...' : 'Resend Code',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendVerificationCode() async {
    try {
      final result = await ApiService.sendVerificationCode(widget.email);
      
      if (result['success'] == true) {
        // In development, the code is returned for testing
        if (result['code'] != null) {
          setState(() {
            _correctCode = result['code'];
          });
        }
        print('✅ Verification code sent to ${widget.email}');
      }
    } catch (e) {
      print('❌ Error sending verification code: $e');
      _showErrorSnackBar('Failed to send verification code. Please try again.');
    }
  }

  Future<void> _verifyCode(BuildContext context) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.verifyCode(widget.email, _verificationCode);
      
      if (result['success'] == true) {
        _showSuccessSnackBar('Email verified successfully!');
        await _exitAnimation();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalDetailsScreen(name: widget.name, email: widget.email),
          ),
        );
      } else {
        _showErrorSnackBar(result['error'] ?? 'Invalid verification code');
        _clearCode();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Verification failed: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    
    try {
      final result = await ApiService.sendVerificationCode(widget.email);
      
      if (result['success'] == true) {
        // In development, the code is returned for testing
        if (result['code'] != null) {
          setState(() {
            _correctCode = result['code'];
          });
        }
        
        setState(() {
          _canResend = false;
          _resendTimer = 60;
          _isResending = false;
        });
        
        _startResendTimer();
        _showSuccessSnackBar('Verification code resent to ${widget.email}');
      } else {
        setState(() => _isResending = false);
        _showErrorSnackBar('Failed to resend code');
      }
    } catch (e) {
      setState(() => _isResending = false);
      _showErrorSnackBar('Failed to resend code');
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _verificationCode = '';
    _focusNodes[0].requestFocus();
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
    