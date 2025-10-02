import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main_dashboard_screen.dart';
import 'personal_details_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Added name controller
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;
  
  bool _isLoading = false;
  bool _hasEmailError = false;
  bool _hasNameError = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '413218401489-td2q4g9cnvoudh69fm0tketpobb7g5ah.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startEntryAnimation();
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
    _emailController.dispose();
    _nameController.dispose();
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
                        _buildLogo(),
                        const SizedBox(height: 60),
                        _buildSignUpForm(),
                        const SizedBox(height: 32),
                        _buildSignUpButton(),
                        const SizedBox(height: 24),
                        _buildSignInLink(),
                        const SizedBox(height: 24),
                        _buildGoogleSignInButton(),
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

  Widget _buildLogo() {
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
              Icons.security,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your UM student email to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SlideTransition(
      position: _slideAnim,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildNameField(),
            const SizedBox(height: 20),
            _buildEmailField(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only @siswa.um.edu.my email addresses are allowed',
                      style: TextStyle(
                        color: Colors.blue,
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

  Widget _buildNameField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hasNameError
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: TextFormField(
        controller: _nameController,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        onChanged: (value) {
          setState(() {
            _hasNameError = false;
          });
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            setState(() => _hasNameError = true);
            return 'Please enter your full name';
          }
          if (value.trim().length < 2) {
            setState(() => _hasNameError = true);
            return 'Name must be at least 2 characters long';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Full Name',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.person_outline,
            color: _hasNameError ? Colors.red : Colors.white.withOpacity(0.7),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hasEmailError
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        onChanged: (value) {
          setState(() {
            _hasEmailError = false;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            setState(() => _hasEmailError = true);
            return 'Please enter your student email';
          }
          
          final email = value.toLowerCase().trim();
          print('Signup email field validation - Input: "$value"');
          print('Signup email field validation - Processed: "$email"');
          
          // Basic email regex validation
          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
            setState(() => _hasEmailError = true);
            print('Signup email field validation - Regex failed for: $email');
            return 'Please enter a valid email address';
          }
          
          // Domain validation - ENABLED
          if (!email.endsWith('@siswa.um.edu.my')) {
            setState(() => _hasEmailError = true);
            return 'Only UM student emails (@siswa.um.edu.my) are allowed';
          }
          
          print('Signup email field validation - SUCCESS for: $email');
          return null;
        },
        decoration: InputDecoration(
          hintText: 'UM Student Email (@siswa.um.edu.my)',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.school_outlined,
            color: _hasEmailError ? Colors.red : Colors.white.withOpacity(0.7),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
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
              onPressed: _isLoading ? null : () => _signUp(context),
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
                      'Create Account',
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

  Widget _buildSignInLink() {
    return SlideTransition(
      position: _slideAnim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Colors.purpleAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SlideTransition(
      position: _slideAnim,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        icon: const Icon(Icons.login),
        label: const Text('Sign in with Google'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _signUp(BuildContext context) async {
    if (_isLoading) return;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final name = _nameController.text.trim();
      
      print('📝 Registering user: $name ($email)');
      
      // Register user in database
      final result = await ApiService.registerUser(
        email: email,
        name: name,
      );
      
      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        final userId = user['userId'];
        
        print('✅ User registered successfully: $userId');
        
        // Save user credentials using helper method
        await ApiService.saveUserCredentials(
          userId: userId,
          email: email,
          name: name,
        );
        
        // Show success message
        if (mounted) {
          _showSuccessSnackBar('Account created successfully! Welcome, $name!');
          
          // Navigate to main dashboard
          await _exitAnimation();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainDashboardScreen(),
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Registration error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to create account: ${e.toString()}');
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

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // Check if the email is from the allowed domain
        final email = googleUser.email.toLowerCase();
        print('Google Sign-In email: $email');
        print('Checking if email ends with: @siswa.um.edu.my');
        print('Email ends with domain: ${email.endsWith('@siswa.um.edu.my')}');
        
        // Domain validation - ENABLED
        if (!email.endsWith('@siswa.um.edu.my')) {
          _showErrorSnackBar('Only UM student emails (@siswa.um.edu.my) are allowed. Your email: $email');
          await _googleSignIn.signOut(); // Sign out the user
          setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        final String? accessToken = googleAuth.accessToken;
        
        if (idToken != null && accessToken != null) {
          print('Google ID Token: $idToken');
          
          final name = googleUser.displayName ?? email.split('@')[0];
          
          // Check if user already exists in database
          print('🔍 Checking if user exists in database...');
          final checkResult = await ApiService.checkUserExists(email);
          
          if (checkResult['exists'] == true && checkResult['user'] != null) {
            // User already registered - auto-login
            final user = checkResult['user'];
            print('✅ User already registered! Auto-logging in...');
            
            await ApiService.saveUserCredentials(
              userId: user['userId'],
              email: user['email'],
              name: user['name'],
            );
            
            _showSuccessSnackBar('Welcome back, ${user['name']}!');
            
            // Navigate directly to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainDashboardScreen(),
              ),
            );
          } else {
            // New user - go to Personal Details Screen
            print('🆕 New user - redirecting to Personal Details');
            _showSuccessSnackBar('Signed in with Google! Please complete your profile.');
            
            // Navigate to Personal Details Screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalDetailsScreen(
                  name: name,
                  email: email,
                ),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Failed to get authentication tokens');
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print('Error during Google Sign-In: $error');
      _showErrorSnackBar('Google Sign-In failed: $error');
      setState(() => _isLoading = false);
    }
  }
}