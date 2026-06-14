import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const Color primaryBlack = Color(0xFF121212);
  static const Color inDriveGreen = Color(0xFFC6FF00);

  static final Stream<QuerySnapshot> usersStream =
  FirebaseFirestore.instance.collection('users').snapshots(
    includeMetadataChanges: false,
  );

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  String? adminEmail;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    print("AUTH USER: ${user?.uid}");

    if (user == null) {
      print("⚠️ AUTH NOT READY OR USER NOT LOGGED IN");
    } else {
      adminEmail = user.email;
      print("ADMIN EMAIL: $adminEmail");
    }
  }

  // ================= SAFE AUTH GUARD =================
  bool get isAdminUser {
    return FirebaseAuth.instance.currentUser?.email ==
        "zrarakbar1@gmail.com";
  }

  @override
  Widget build(BuildContext context) {

     final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
    return StreamBuilder<QuerySnapshot>(
      stream: AdminDashboardScreen.usersStream,
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Firestore Error:\n${snapshot.error}"));
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          return data['role']?.toString() == role;
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user =
            Map<String, dynamic>.from(users[index].data() as Map);
            final userId = users[index].id;

            return _buildUserCard(context, user, userId);
          },
        );
      },
    );
  }

  // ================= PENDING =================
  Widget _buildPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminDashboardScreen.usersStream,
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Firestore Error:\n${snapshot.error}"));
        }

        final pendingUsers = snapshot.data!.docs.where((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map);

          return (data['isVerified'] ?? false) == false &&
              data['role']?.toString() != 'admin';
        }).toList();

        return ListView.builder(
          itemCount: pendingUsers.length,
          itemBuilder: (context, index) {
            final user =
            Map<String, dynamic>.from(pendingUsers[index].data() as Map);
            final userId = pendingUsers[index].id;

            return _buildUserCard(context, user, userId);
          },
        );
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