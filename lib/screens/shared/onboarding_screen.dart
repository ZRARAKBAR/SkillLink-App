import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:skilllink_app/auth/login_screen.dart'; // ADDED: Correct path to find LoginScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    const Color inDriveGreen = Color(0xFFC6FF00);
    const Color primaryBlack = Color(0xFF121212);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildModernPage(
                  'assets/images/onboard_screen1.json',
                  "Expert Help\nin Sahiwal",
                  "Connect with top-rated electricians and plumbers instantly.",
                  inDriveGreen, primaryBlack
              ),
              _buildModernPage(
                  'assets/images/Deal.json',
                  "Fair Bidding\nSystem",
                  "No fixed rates. Suggest your price and negotiate like a pro.",
                  inDriveGreen, primaryBlack
              ),
              _buildModernPage(
                  'assets/images/verfication.json',
                  "Verified & \nSecure",
                  "Safety first. Every worker is verified by the SkillLink team.",
                  inDriveGreen, primaryBlack,
                  isLast: true
              ),
            ],
          ),

          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
               onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen())),
              child: const Text("SKIP", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
          ),

          Positioned(
            bottom: 50,
            left: 30,
            child: Row(
              children: List.generate(3, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? primaryBlack : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPage(String imgPath, String title, String desc, Color accent, Color textCol, {bool isLast = false}) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            color: Colors.grey[100],
            child: Center(
              child: imgPath.endsWith('.json')
                  ? Lottie.asset(
                imgPath,
                fit: BoxFit.contain,
              )
                  : Image.asset(
                imgPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(30),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1),
                ),
                const SizedBox(height: 15),
                Text(
                  desc,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
                ),
                const Spacer(),
                if (isLast)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textCol,
                        foregroundColor: accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                       onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen())),
                      child: const Text("GET STARTED", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      backgroundColor: textCol,
                      child: Icon(Icons.arrow_forward_ios, color: accent, size: 18),
                      onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}