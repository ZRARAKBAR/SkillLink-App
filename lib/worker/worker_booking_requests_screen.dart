import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerBookingRequestsScreen extends StatefulWidget {
  const WorkerBookingRequestsScreen({super.key});

  @override
  State<WorkerBookingRequestsScreen> createState() =>
      _WorkerBookingRequestsScreenState();
}

class _WorkerBookingRequestsScreenState
    extends State<WorkerBookingRequestsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("workerId", isEqualTo: uid)
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No new requests"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Booking from Customer"),
                  subtitle: Text("Status: ${data['status']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection("bookings")
                              .doc(id)
                              .update({"status": "accepted"});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection("bookings")
                              .doc(id)
                              .update({"status": "rejected"});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}