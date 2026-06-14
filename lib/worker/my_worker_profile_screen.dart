import 'package:flutter/material.dart';
import 'package:skilllink_app/worker/worker_dashboard_screen.dart';

class MyWorkerProfileScreen extends StatefulWidget {
  const MyWorkerProfileScreen({super.key});

  @override
  State<MyWorkerProfileScreen> createState() =>
      _MyWorkerProfileScreenState();
}

class _MyWorkerProfileScreenState extends State<MyWorkerProfileScreen> {
  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color bgGrey = const Color(0xFFF5F5F5);

  String? selectedService;
  final List<String> services = [
    "Electrician",
    "Plumber",
    "Carpenter",
    "Painter",
    "AC Technician",
    "Cleaner"
  ];

  final TextEditingController _experienceController =
  TextEditingController();

  void _submitProfile() {
    if (selectedService == null ||
        _experienceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete profile details'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Profile Updated Successfully!',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: inDriveGreen,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (c) => const WorkerDashboardScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Profile",
              style:
              TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration:
              const InputDecoration(labelText: "Main Skill"),
              items: services
                  .map((s) =>
                  DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => selectedService = val),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Years of Experience",
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: bgGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Note: Document upload is handled in Profile Setup screen.",
                style: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlack,
                ),
                onPressed: _submitProfile,
                child: Text(
                  "SAVE PROFILE",
                  style: TextStyle(color: inDriveGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}