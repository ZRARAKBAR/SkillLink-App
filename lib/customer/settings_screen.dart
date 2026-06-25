import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool darkMode = false;
  bool locationTracking = true;

  final Color dark = const Color(0xFF121212);
  final Color accent = const Color(0xFFC6FF00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: dark,
        title: const Text("Settings"),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _sectionTitle("Account"),

          _tile(
            icon: Icons.person,
            title: "Edit Profile",
            onTap: () {},
          ),

          _tile(
            icon: Icons.lock,
            title: "Change Password",
            onTap: () {},
          ),

          const SizedBox(height: 20),

          _sectionTitle("Preferences"),

          SwitchListTile(
            value: notifications,
            activeColor: accent,
            title: const Text("Notifications"),
            subtitle: const Text("Enable app notifications"),
            onChanged: (val) {
              setState(() => notifications = val);
            },
          ),

          SwitchListTile(
            value: locationTracking,
            activeColor: accent,
            title: const Text("Location Tracking"),
            subtitle: const Text("Allow job matching by location"),
            onChanged: (val) {
              setState(() => locationTracking = val);
            },
          ),

          SwitchListTile(
            value: darkMode,
            activeColor: accent,
            title: const Text("Dark Mode"),
            subtitle: const Text("Enable dark theme"),
            onChanged: (val) {
              setState(() => darkMode = val);
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle("Privacy & Security"),

          _tile(
            icon: Icons.privacy_tip,
            title: "Privacy Policy",
            onTap: () {},
          ),

          _tile(
            icon: Icons.security,
            title: "Security Settings",
            onTap: () {},
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () {},
            child: const Text("Delete Account"),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}