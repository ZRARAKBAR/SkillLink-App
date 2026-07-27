import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const Color primaryBlack = Color(0xFF121212);
  static const Color inDriveGreen = Color(0xFFC6FF00);

  static const String adminEmail = "zrarakbar1@gmail.com";

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Single, long-lived subscription owned by this State object.
  // All three tabs read from the SAME cached snapshot below instead of
  // each tab creating its own StreamBuilder/subscription. That was the
  // actual bug: TabBarView only builds a tab's widget the first time you
  // swipe into it, so a per-tab StreamBuilder was racing network latency
  // every time, and any parent rebuild created a brand new Stream object,
  // resetting that tab back to "waiting" — hence the spinner reappearing.
  StreamSubscription<QuerySnapshot>? _usersSub;
  QuerySnapshot? _usersSnapshot;
  Object? _usersError;

  @override
  void initState() {
    super.initState();
    _usersSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen(
          (snapshot) {
        if (!mounted) return;
        setState(() {
          _usersSnapshot = snapshot;
          _usersError = null;
        });
      },
      onError: (error) {
        debugPrint("Firestore error: $error");
        if (!mounted) return;
        setState(() {
          _usersError = error;
        });
      },
    );
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state instead of reading currentUser once.
    // currentUser can be null for a moment (or indefinitely for this
    // widget) while Firebase is still restoring the persisted session.
    // Without a listener, the UI never rebuilds once the user loads,
    // which is what was causing the endless spinner originally.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text("You must be signed in to view this page."),
            ),
          );
        }

        if (user.email != AdminDashboardScreen.adminEmail) {
          return const Scaffold(
            body: Center(
              child: Text("You are not authorized to view this page."),
            ),
          );
        }

        return _buildDashboard(context);
      },
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Admin Control Center",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AdminDashboardScreen.primaryBlack,
        foregroundColor: AdminDashboardScreen.inDriveGreen,
        centerTitle: true,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AdminDashboardScreen.primaryBlack,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AdminDashboardScreen.inDriveGreen,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Customers"),
                  Tab(text: "Workers"),
                  Tab(text: "Pending"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUserList("customer"),
                  _buildUserList("worker"),
                  _buildPendingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= USERS =================
  Widget _buildUserList(String role) {
    if (_usersError != null) {
      return Center(child: Text("Firestore Error:\n$_usersError"));
    }

    if (_usersSnapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = _usersSnapshot!.docs.where((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      return data['role']?.toString() == role;
    }).toList();

    if (users.isEmpty) {
      return Center(child: Text("No $role users found."));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = Map<String, dynamic>.from(users[index].data() as Map);
        final userId = users[index].id;

        return _buildUserCard(context, user, userId);
      },
    );
  }

  // ================= PENDING =================
  Widget _buildPendingList() {
    if (_usersError != null) {
      return Center(child: Text("Firestore Error:\n$_usersError"));
    }

    if (_usersSnapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingUsers = _usersSnapshot!.docs.where((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);

      return (data['isVerified'] ?? false) == false &&
          data['role']?.toString() != 'admin';
    }).toList();

    if (pendingUsers.isEmpty) {
      return const Center(child: Text("No pending users."));
    }

    return ListView.builder(
      itemCount: pendingUsers.length,
      itemBuilder: (context, index) {
        final user =
        Map<String, dynamic>.from(pendingUsers[index].data() as Map);
        final userId = pendingUsers[index].id;

        return _buildUserCard(context, user, userId);
      },
    );
  }

  // ================= USER CARD =================
  Widget _buildUserCard(
      BuildContext context,
      Map<String, dynamic> user,
      String userId,
      ) {
    bool isBanned = (user['isBanned'] ?? false);
    bool isVerified = (user['isVerified'] ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: ListTile(
        title: Text(
          user['fullName'] ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${user['role'] ?? 'N/A'}'),
            Text(
              isVerified ? "Verified" : "Pending Approval",
              style: TextStyle(
                color: isVerified ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isBanned ? Icons.lock : Icons.lock_open,
                color: isBanned ? Colors.red : Colors.grey,
              ),
              onPressed: () => _toggleBanStatus(userId, isBanned),
            ),
            IconButton(
              icon: Icon(
                Icons.verified,
                color: isVerified ? Colors.green : Colors.blue,
              ),
              onPressed: isVerified ? null : () => _verifyUser(userId),
            ),
          ],
        ),
        onTap: () => _showUserDetails(context, user),
      ),
    );
  }

  // ================= ACTIONS =================
  Future<void> _toggleBanStatus(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isBanned': !currentStatus});
  }

  Future<void> _verifyUser(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isVerified': true});
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(user['fullName'] ?? "User"),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }
}
