import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_tracking_screen.dart';

class CustomerActiveTasksScreen extends StatelessWidget {
  const CustomerActiveTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Tasks"),
        backgroundColor: const Color(0xFF121212),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("customerId", isEqualTo: uid)
            .where("status", whereIn: ["pending", "accepted", "in_progress"])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No active tasks"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data["workerName"] ?? "Worker"),
                  subtitle: Text("Status: ${data["status"]}"),
                  trailing: const Icon(Icons.arrow_forward_ios),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingTrackingScreen(
                          bookingId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}