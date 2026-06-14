import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skilllink_app/auth/login_screen.dart';
import 'package:skilllink_app/worker/send_offer_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  int _bottomIndex = 0;

  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color bgGrey = const Color(0xFFF5F5F5);

  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Map<String, dynamic>? _workerProfile;

  @override
  void initState() {
    super.initState();
    _listenToWorkerProfile();
  }

  // Active Profile & Ban Status enforcement sync
  void _listenToWorkerProfile() {
    if (_currentUid.isEmpty) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;

        // Instant Active Ban Boot Out Check
        if (data['isBanned'] == true) {
          FirebaseAuth.instance.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (c) => const LoginScreen()),
                (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session Expired: Your account has been suspended by the administrator."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _workerProfile = data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _bottomIndex == 0
              ? "Available Task Hub"
              : _bottomIndex == 1 ? "Active Proposals" : "Professional Profile",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _bottomIndex,
        children: [
          _buildDashboardFeed(),
          _buildBidsFeed(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        selectedItemColor: primaryBlack,
        unselectedItemColor: Colors.grey[400],
        onTap: (index) => setState(() => _bottomIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: "Jobs"),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: "My Bids"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  // ==========================================================
  // VIEW TAB 1: LIVE TASKS STREAM
  // ==========================================================
  Widget _buildDashboardFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final tasks = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildEarningsCard(),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("New Tasks Near You",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${tasks.length} Live",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            if (tasks.isEmpty)
              _buildEmptyState("No jobs posted yet in your area.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  var taskData = tasks[index].data() as Map<String, dynamic>;
                  String taskId = tasks[index].id;
                  return _buildTaskCard(taskData, taskId);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEarningsCard() {
    String balance = _workerProfile?['walletBalance'] ?? "0";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: primaryBlack,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weekly Balance", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 5),
              Text("Rs. $balance", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          CircleAvatar(
              backgroundColor: inDriveGreen,
              radius: 25,
              child: const Icon(Icons.account_balance_wallet, color: Colors.black)
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, String taskId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)),
                child: Text(task['category'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Text("Rs. ${task['budget'] ?? task['budget_expected'] ?? 'N/A'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(task['title'] ?? 'No Title Provided', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(task['description'] ?? '', style: TextStyle(color: Colors.grey[700], height: 1.4)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlack,
                  foregroundColor: inDriveGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const SendOfferScreen())
                );
              },
              child: const Text("SEND OFFER", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================================
  // VIEW TAB 2: PERSONAL BIDS PROPOSALS
  // ==========================================================
  Widget _buildBidsFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('offers')
          .where('workerId', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final offers = snapshot.data?.docs ?? [];

        if (offers.isEmpty) {
          return _buildEmptyState("You haven't made any offers yet.");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            var offer = offers[index].data() as Map<String, dynamic>;
            String status = offer['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text("Proposed: Rs. ${offer['price'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text("Notes: ${offer['message'] ?? 'No comments.'}"),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'accepted'
                        ? Colors.green.withOpacity(0.2)
                        : status == 'rejected' ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status == 'accepted'
                          ? Colors.green.shade800
                          : status == 'rejected' ? Colors.red.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // VIEW TAB 3: PROFILE INTERFACE
  // ==========================================================
  Widget _buildProfileView() {
    if (_workerProfile == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    String imageUrl = _workerProfile?['profileImage'] ?? '';
    String skills = _workerProfile?['skills'] ?? 'Not Configured';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: inDriveGreen,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? const Icon(Icons.person, size: 45, color: Colors.black) : null,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _workerProfile?['fullName'] ?? _workerProfile?['name'] ?? 'User Profile',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _workerProfile?['email'] ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 30),
        const Text("Professional Credentials", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.psychology, color: Colors.black),
          title: const Text("Core Expertise / Skills"),
          subtitle: Text(skills),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.star, color: Colors.orange),
          title: const Text("Performance Rating"),
          subtitle: Text("${_workerProfile?['rating'] ?? '4.8'} / 5.0 Star Target"),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 70, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    String name = _workerProfile?['fullName'] ?? _workerProfile?['name'] ?? 'ZRAR AKBAR';
    String rating = _workerProfile?['rating'] ?? '4.9';
    String imgUrl = _workerProfile?['profileImage'] ?? '';

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryBlack),
            accountName: Text(name.toUpperCase()),
            accountEmail: Text("Rating: ⭐ $rating"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: inDriveGreen,
              backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
              child: imgUrl.isEmpty
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : "Z",
                  style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const ListTile(leading: Icon(Icons.history), title: Text("Job History")),
          const ListTile(leading: Icon(Icons.wallet), title: Text("Withdraw Earnings")),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (c) => const LoginScreen()),
                      (r) => false
              );
            },
          ),
        ],
      ),
    );
  }
}