import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  final Color dark = const Color(0xFF121212);
  final Color accent = const Color(0xFFC6FF00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: dark,
        title: const Text("Support"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 10),

            _supportCard(
              icon: Icons.chat,
              title: "Live Chat Support",
              subtitle: "Talk to our support team instantly",
              onTap: () {},
            ),

            _supportCard(
              icon: Icons.email,
              title: "Email Support",
              subtitle: "skilllink.support@gmail.com",
              onTap: () {},
            ),

            _supportCard(
              icon: Icons.phone,
              title: "Call Support",
              subtitle: "+92 300 0000000",
              onTap: () {},
            ),

            _supportCard(
              icon: Icons.help_outline,
              title: "FAQs",
              subtitle: "Common questions & answers",
              onTap: () {},
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "We usually respond within 24 hours. For urgent issues, use call support.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}