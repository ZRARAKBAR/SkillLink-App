import 'package:flutter/material.dart';
import 'package:skilllink_app/customer/customer_home_screen.dart';
import 'package:skilllink_app/worker/worker_profile_setup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_verification_screen.dart';
import 'package:lottie/lottie.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color primaryBlack = const Color(0xFF121212);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController =
  TextEditingController();
  final TextEditingController _phoneController =
  TextEditingController();

  bool _isWorker = false;
  bool _isLoading = false;
  bool _showPassword = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passController.text;
    String confirmPassword = _confirmPassController.text;
    String phoneNumber = _phoneController.text.trim();

    if (name.isEmpty) {
      _showError("Full name is required");
      return;
    }

    if (name.length < 3) {
      _showError("Name must be at least 3 characters");
      return;
    }

    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(name)) {
      _showError("Name can only contain letters");
      return;
    }

    if (email.isEmpty) {
      _showError("Email is required");
      return;
    }

    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
        .hasMatch(email)) {
      _showError("Enter a valid email address");
      return;
    }

    if (password.isEmpty) {
      _showError("Password is required");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError("Confirm password is required");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]')
        .hasMatch(password)) {
      _showError("Password must contain letters and numbers");
      return;
    }

    if (_isWorker) {
      if (phoneNumber.isEmpty) {
        _showError("Phone number is REQUIRED for workers");
        return;
      }

      if (!RegExp(r'^\+?[\d\s\-\$\$]{10,}$')
          .hasMatch(phoneNumber)) {
        _showError("Enter valid phone number (10+ digits)");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String chosenRole = _isWorker ? 'worker' : 'customer';

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'fullName': name,
          'email': email,
          'role': chosenRole,
          'isVerified': chosenRole == 'customer',
          'profileSetupCompleted': false,
          'isBanned': false,
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': _isWorker ? phoneNumber : null,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => EmailVerificationScreen(isWorker: _isWorker),
        ),
      );} on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showError(e.message ?? "Authentication failed.");
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(
        "Network error: Please check your connection.",
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                    inDriveGreen.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        -20 * (1 - _fadeAnimation.value),
                      ),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          height: 340,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _isWorker
                                    ? primaryBlack
                                    : inDriveGreen,
                                (_isWorker
                                    ? primaryBlack
                                    : inDriveGreen)
                                    .withOpacity(0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius:
                            const BorderRadius.only(
                              bottomLeft: Radius.circular(60),
                              bottomRight:
                              Radius.circular(60),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isWorker
                                    ? primaryBlack
                                    : inDriveGreen)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding:
                              const EdgeInsets.all(30),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                                children: [
                                  Hero(
                                    tag:
                                    'logo-${_isWorker}',
                                    child: Container(
                                      height: 140,
                                      decoration:
                                      BoxDecoration(
                                        shape:
                                        BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isWorker
                                                ? inDriveGreen
                                                : primaryBlack)
                                                .withOpacity(
                                                0.4),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child:
                                        AnimatedSwitcher(
                                          duration:
                                          const Duration(
                                            milliseconds:
                                            500,
                                          ),
                                          transitionBuilder:
                                              (
                                              child,
                                              animation,
                                              ) =>
                                              ScaleTransition(
                                                scale: Tween<
                                                    double>(
                                                  begin: 0.8,
                                                  end: 1.0,
                                                ).animate(
                                                    animation),
                                                child: child,
                                              ),
                                          child: Image.asset(
                                            _isWorker
                                                ? 'assets/images/lab.PNG'
                                                : 'assets/images/cust.PNG',
                                            key: ValueKey<
                                                bool>(
                                              _isWorker,
                                            ),
                                            height: 140,
                                            width: 140,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 20),
                                  Text(
                                    _isWorker
                                        ? "JOIN AS PROFESSIONAL"
                                        : "JOIN AS CUSTOMER",
                                    textAlign:
                                    TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                      FontWeight.bold,
                                      color: _isWorker
                                          ? inDriveGreen
                                          : Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 10),
                                  Text(
                                    "Create your account to get started",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isWorker
                                          ? inDriveGreen
                                          .withOpacity(
                                          0.8)
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      30, 40, 30, 40),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(
                              25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildEnhancedTab(
                                "Customer",
                                !_isWorker),
                            _buildEnhancedTab(
                                "Worker",
                                _isWorker),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        "Let's get you started",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                          FontWeight.bold,
                          color: primaryBlack,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Enter your details to create account",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 40),

                      _buildEnhancedInput(
                        "Full Name",
                        Icons.person_outline,
                        _nameController,
                      ),

                      const SizedBox(height: 20),

                      _buildEnhancedInput(
                        "Email Address",
                        Icons.email_outlined,
                        _emailController,
                      ),

                      const SizedBox(height: 20),

                      AnimatedContainer(
                        duration:
                        Duration(milliseconds: 300),
                        height: _isWorker ? 70 : 0,
                        child: _isWorker
                            ? _buildEnhancedInput(
                          "Phone Number *REQUIRED*",
                          Icons.phone,
                          _phoneController,
                        )
                            : SizedBox.shrink(),
                      ),

                      const SizedBox(height: 20),

                      _buildEnhancedPasswordInput(),

                      const SizedBox(height: 20),

                      _buildEnhancedConfirmPasswordInput(),

                      const SizedBox(height: 40),

                      Container(
                        width: double.infinity,
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(
                              20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlack
                                  .withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            primaryBlack,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                  20),
                            ),
                            elevation: 0,
                            padding:
                            EdgeInsets.zero,
                          ),
                          onPressed: _isLoading
                              ? null
                              : _handleContinue,
                          child: _isLoading
                              ? Container(
                            padding:
                            const EdgeInsets
                                .all(20),
                            child:
                            CircularProgressIndicator(
                              color:
                              inDriveGreen,
                              strokeWidth: 3,
                            ),
                          )
                              : Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration:
                                  BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(
                                        20),
                                    gradient:
                                    LinearGradient(
                                      colors: [
                                        primaryBlack,
                                        primaryBlack
                                            .withOpacity(
                                            0.9),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  "CREATE ACCOUNT",
                                  style:
                                  TextStyle(
                                    color:
                                    inDriveGreen,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                    fontSize:
                                    18,
                                    letterSpacing:
                                    1.2,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTab(
      String label,
      bool active,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(
              () => _isWorker =
          (label == "Worker"),
        ),
        child: AnimatedContainer(
          duration:
          const Duration(milliseconds: 300),
          padding:
          const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: active
                ? (_isWorker
                ? inDriveGreen
                : primaryBlack)
                : Colors.transparent,
            borderRadius:
            BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 16,
                color: active
                    ? (_isWorker
                    ? primaryBlack
                    : Colors.white)
                    : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedInput(
      String hint,
      IconData icon,
      TextEditingController controller,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding:
            const EdgeInsets.all(18),
            child: Icon(
              icon,
              color:
              primaryBlack.withOpacity(0.7),
              size: 24,
            ),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 0,
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide(
              color: primaryBlack,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passController,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding:
            const EdgeInsets.all(18),
            child: Icon(
              Icons.lock_outline,
              color:
              primaryBlack.withOpacity(0.7),
              size: 24,
            ),
          ),
          suffixIcon: Padding(
            padding:
            const EdgeInsets.all(18),
            child: GestureDetector(
              onTap: () => setState(
                    () => _showPassword =
                !_showPassword,
              ),
              child: Icon(
                _showPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: primaryBlack
                    .withOpacity(0.7),
                size: 24,
              ),
            ),
          ),
          hintText: "Password",
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 0,
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide(
              color: primaryBlack,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedConfirmPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _confirmPassController,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding:
            const EdgeInsets.all(18),
            child: Icon(
              Icons.lock_reset_outlined,
              color:
              primaryBlack.withOpacity(0.7),
              size: 24,
            ),
          ),
          suffixIcon: Padding(
            padding:
            const EdgeInsets.all(18),
            child: GestureDetector(
              onTap: () => setState(
                    () => _showPassword =
                !_showPassword,
              ),
              child: Icon(
                _showPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: primaryBlack
                    .withOpacity(0.7),
                size: 24,
              ),
            ),
          ),
          hintText: "Confirm Password",
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 0,
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(20),
            borderSide: BorderSide(
              color: primaryBlack,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}