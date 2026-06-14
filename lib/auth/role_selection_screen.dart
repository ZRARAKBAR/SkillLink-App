import 'package:flutter/material.dart';
import '../customer/customer_home_screen.dart';
import '../worker/worker_profile_setup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color primaryBlack = const Color(0xFF121212);

  String selectedRole = '';

  void _finishSignUp() {
    if (selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role first!')),
      );
      return;
    }

    if (selectedRole == 'customer') {
      // Show SnackBar first so the context remains valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Account created! Welcome to SkillLink.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: inDriveGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate after SnackBar is triggered
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const CustomerHomeScreen()),
            (route) => false,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const WorkerProfileSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryBlack),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose\nYour Role",
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: primaryBlack,
                    height: 1.1),
              ),
              const SizedBox(height: 10),
              Text(
                "How do you want to use SkillLink?",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              GestureDetector(
                onTap: () => setState(() => selectedRole = 'customer'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: selectedRole == 'customer' ? primaryBlack : Colors.white,
                    border: Border.all(color: primaryBlack, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_search,
                          size: 40,
                          color: selectedRole == 'customer'
                              ? inDriveGreen
                              : primaryBlack),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("I am a Customer",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: selectedRole == 'customer'
                                        ? Colors.white
                                        : primaryBlack)),
                            Text("I want to hire skilled workers.",
                                style: TextStyle(
                                    color: selectedRole == 'customer'
                                        ? Colors.grey[400]
                                        : Colors.grey[600])),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => setState(() => selectedRole = 'worker'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: selectedRole == 'worker' ? primaryBlack : Colors.white,
                    border: Border.all(color: primaryBlack, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.handyman,
                          size: 40,
                          color: selectedRole == 'worker'
                              ? inDriveGreen
                              : primaryBlack),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("I am a Worker",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: selectedRole == 'worker'
                                        ? Colors.white
                                        : primaryBlack)),
                            Text("I want to offer my services.",
                                style: TextStyle(
                                    color: selectedRole == 'worker'
                                        ? Colors.grey[400]
                                        : Colors.grey[600])),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlack,
                    foregroundColor: inDriveGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _finishSignUp,
                  child: const Text("COMPLETE SIGN UP",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}