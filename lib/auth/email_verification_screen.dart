import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skilllink_app/customer/customer_home_screen.dart';
import 'package:skilllink_app/worker/worker_profile_setup_screen.dart';


class EmailVerificationScreen extends StatefulWidget {
  final bool isWorker;

  const EmailVerificationScreen({super.key, required this.isWorker});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerified = false;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Auto-check every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _loading = true);

    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      _isVerified = true;

      // 🔥 Firestore sync
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isVerified': true,
      });

      _timer?.cancel();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.isWorker
              ? const WorkerProfileSetupScreen()
              : const CustomerHomeScreen(),
        ),
      );
    }

    setState(() => _loading = false);
  }

  Future<void> _resendEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.sendEmailVerification();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Verification email resent"),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Verify Your Email",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "We have sent a verification link to your email.\nPlease verify to continue.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              if (_loading)
                const CircularProgressIndicator(),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _checkEmailVerified,
                child: const Text("I have verified"),
              ),

              TextButton(
                onPressed: _resendEmail,
                child: const Text("Resend Email"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}