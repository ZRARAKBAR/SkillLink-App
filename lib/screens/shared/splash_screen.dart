import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // inDrive Inspired Brand Colors
  static const Color indriveBackground = Color(0xFF0E0E10); // Ultra clean tech dark
  static const Color indriveNeonGreen = Color(0xFF00CC44);  // Pure brand energetic green
  static const Color indriveGlowColor = Color(0xFF00FF66);  // Bright neon flare

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Slightly reduced offset for a tighter tech look
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.fastLinearToSlowEaseIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

     _videoController = VideoPlayerController.asset('assets/images/logo.mp4')
      ..initialize().then((_) {
        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController.play();
          }
        });
      });

    // 4-second splash timer
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: indriveBackground, // Updated base background color
      body: SafeArea(
        child: Stack(
          children: [

            /// Top glow circle (Updated to neon brand green flare)
            Positioned(
              top: -120,
              right: -60,
              child: _buildBlurCircle(
                indriveGlowColor.withOpacity(0.12),
                280,
              ),
            ),

            /// Bottom glow circle (Updated to match inDrive palette profile)
            Positioned(
              bottom: -80,
              left: -60,
              child: _buildBlurCircle(
                indriveNeonGreen.withOpacity(0.15),
                320,
              ),
            ),

            /// Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// Video display container matching logo dimensions
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      height: 280,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _isVideoInitialized
                            ? AspectRatio(
                          key: const ValueKey('video_player'),
                          aspectRatio: _videoController.value.aspectRatio,
                          child: VideoPlayer(_videoController),
                        )
                            : Image.asset(
                          'assets/images/Skill_logo.png',
                          key: const ValueKey('placeholder_pic'),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.bolt, // High energy brand backup icon
                                color: indriveNeonGreen,
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// Text details
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            "Connecting Skills with Opportunities",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Developed By: Zrar Akbar & Tabia Nasir",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.45),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  _buildModernLoader(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 65, // Smoother blurs for premium look
          sigmaY: 65,
        ),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildModernLoader() {
    return SizedBox(
      width: 45,
      height: 2.5,
      child: LinearProgressIndicator(
        backgroundColor: Colors.white.withOpacity(0.08),
        valueColor: const AlwaysStoppedAnimation<Color>(
          indriveNeonGreen, // Updated tracker line to dynamic neon green
        ),
      ),
    );
  }
}