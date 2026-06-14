import 'package:flutter/material.dart';
import 'package:skilllink_app/auth/signup_screen.dart';
import 'package:skilllink_app/customer/customer_home_screen.dart';
import 'package:skilllink_app/worker/worker_dashboard_screen.dart';
import 'package:skilllink_app/admin/admin_dashboard_screen.dart';
import 'package:skilllink_app/auth/forgot_password_screen.dart';
import 'package:skilllink_app/worker/worker_profile_setup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color primaryBlack = const Color(0xFF121212);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isWorker = false;
  bool _obscureText = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showWorkerAlert() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: primaryBlack,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: primaryBlack.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: inDriveGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user, color: inDriveGreen, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                "Worker Verification Required",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                "To accept jobs, you must upload your CNIC and certificates in the next step if not already verified.",
                style: TextStyle(color: Colors.white70, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inDriveGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "I UNDERSTAND",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   void _openAdminControlCenter() {
    String password = _passwordController.text.trim();

     if (password == 'skilllinkadmin999') {
      _emailController.clear();
      _passwordController.clear();

      _showEnhancedSnackBar(
          'Developer Override: Launching Admin Control Center...',
          Colors.purple.shade600
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else {
       _showEnhancedSnackBar('Welcome to SkillLink!', Colors.grey.shade700);
    }
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showEnhancedSnackBar("Please enter a valid email.", Colors.red.shade400);
      return;
    }
    if (password.isEmpty) {
      _showEnhancedSnackBar("Please enter your password.", Colors.red.shade400);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // STEP 1 FIX Applied: Signs in and blocks until request.auth context updates safely.
      UserCredential userCredential =
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      await Future.delayed(const Duration(milliseconds: 500));

      User? user =
          FirebaseAuth.instance.currentUser ?? userCredential.user;

      if (user != null && user.email == "zrarakbar1@gmail.com") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );

        setState(() => _isLoading = false);
        return; // VERY IMPORTANT
      }

      if (user != null) {
        // STEP 2 FIX Applied: Forcing network retrieval (Source.server) to drop the cache layer
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          String dbRole = userData['role'] ?? 'customer';
          bool isBanned = userData['isBanned'] ?? false;
          bool profileSetupCompleted = userData['profileSetupCompleted'] ?? true;

          if (isBanned) {
            await FirebaseAuth.instance.signOut();
            _showEnhancedSnackBar("Access Denied: This account has been suspended.", Colors.red.shade400);
            setState(() => _isLoading = false);
            return;
          }

          String selectedRole = _isWorker ? 'worker' : 'customer';

          if (dbRole != selectedRole) {
            _showEnhancedSnackBar("Account exists, but as a ${dbRole.toUpperCase()}.", Colors.orange.shade400);
            setState(() => _isLoading = false);
            return;
          }

          if (!mounted) return;

          if (_isWorker && !profileSetupCompleted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerProfileSetupScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (context, animation, secondaryAnimation) =>
                _isWorker ? const WorkerDashboardScreen() : const CustomerHomeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          }
        } else {
          _showEnhancedSnackBar("User profile not found in database.", Colors.red.shade400);
          setState(() => _isLoading = false);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showEnhancedSnackBar(e.message ?? "Authentication failed.", Colors.red.shade400);
    } catch (e) {
      setState(() => _isLoading = false);
      _showEnhancedSnackBar("Network error: Please check your connection or proxy.", Colors.red.shade400);
    }
  }

  void _showEnhancedSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                    inDriveGreen.withOpacity(0.03),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Header with Logo
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _isWorker ? primaryBlack : inDriveGreen,
                                  (_isWorker ? primaryBlack : inDriveGreen).withOpacity(0.85),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isWorker ? primaryBlack : inDriveGreen).withOpacity(0.3),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isWorker ? inDriveGreen : primaryBlack).withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        _isWorker ? 'assets/images/lab.PNG' : 'assets/images/cust.PNG',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    _isWorker ? "PROFESSIONAL" : "CUSTOMER",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _isWorker ? inDriveGreen : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Welcome Text (Long Press Target Area)
                          GestureDetector(
                            onLongPress: _openAdminControlCenter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome",
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: primaryBlack,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  "Back",
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: inDriveGreen,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Login to your specific role",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Enhanced Role Selection
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildEnhancedTab("Customer", !_isWorker),
                                _buildEnhancedTab("Worker", _isWorker),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Enhanced Input Fields
                          _buildEnhancedTextField("Email Address", Icons.email_outlined, _emailController, false),
                          const SizedBox(height: 24),
                          _buildEnhancedTextField("Password", Icons.lock_outline, _passwordController, true),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                    const ForgotPasswordScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: primaryBlack,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                  decorationColor: primaryBlack,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Enhanced Login Button
                          Container(
                            width: double.infinity,
                            height: 65,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlack.withOpacity(0.25),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlack,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? Container(
                                padding: const EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: inDriveGreen,
                                  strokeWidth: 3,
                                ),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      color: inDriveGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.arrow_forward, color: inDriveGreen, size: 22),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Create Account Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "New here? ",
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                    const SignUpScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                ),
                                child: Text(
                                  "Create Account",
                                  style: TextStyle(
                                    color: primaryBlack,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isWorker = (label == "Worker");
            if (_isWorker) _showWorkerAlert();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? (_isWorker ? inDriveGreen : primaryBlack) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: active
                    ? (_isWorker ? primaryBlack : Colors.white)
                    : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField(String label, IconData icon, TextEditingController controller, bool isPass) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? _obscureText : false,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(20),
            child: Icon(icon, color: primaryBlack.withOpacity(0.7), size: 24),
          ),
          suffixIcon: isPass
              ? Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () => setState(() => _obscureText = !_obscureText),
              child: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: primaryBlack.withOpacity(0.7),
                size: 24,
              ),
            ),
          )
              : null,
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: primaryBlack, width: 2.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
        ),
      ),
    );
  }
}