import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skilllink_app/customer/view_worker_profile_screen.dart';
import 'package:skilllink_app/customer/booking_tracking_screen.dart';

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  static const Color primaryBlack = Color(0xFF121212);
  static const Color inDriveGreen = Color(0xFFC6FF00);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Worker Offers",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("offers")
            .where("customerId", isEqualTo: uid)
            .snapshots(), // 👈 removed status filter for debugging stability

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No offers available"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return _buildOfferCard(
                context,
                data,
                docs[index].id,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(
      BuildContext context,
      Map<String, dynamic> data,
      String offerId,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF121212),
                child: Icon(Icons.person, color: Color(0xFFC6FF00)),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["workerName"]?.toString() ?? "Worker",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "⭐ ${data["rating"]?.toString() ?? "4.9"}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                "Rs. ${data["price"]?.toString() ?? "0"}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            data["message"]?.toString() ?? "No message",
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewWorkerProfileScreen(
                          workerId: data["workerId"]?.toString() ?? "",
                        ),
                      ),
                    );
                  },
                  child: const Text("VIEW PROFILE"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlack,
                    foregroundColor: inDriveGreen,
                  ),

                  onPressed: () async {
                    final offerRef = FirebaseFirestore.instance
                        .collection("offers")
                        .doc(offerId);

                    final taskId = data["taskId"];
                    final workerId = data["workerId"];
                    final customerId = data["customerId"];

                    if (taskId == null || workerId == null || customerId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid offer data")),
                      );
                      return;
                    }

                    // 🔒 check if already booked
                    final existing = await FirebaseFirestore.instance
                        .collection("bookings")
                        .where("taskId", isEqualTo: taskId)
                        .get();

                    if (existing.docs.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Already hired for this task"),
                        ),
                      );
                      return;
                    }

                    final batch = FirebaseFirestore.instance.batch();

                    final taskRef = FirebaseFirestore.instance
                        .collection("tasks")
                        .doc(taskId);

                    final bookingRef = FirebaseFirestore.instance
                        .collection("bookings")
                        .doc();

                    // ✅ accept offer
                    batch.update(offerRef, {"status": "accepted"});

                    // ✅ update task
                    batch.update(taskRef, {
                      "status": "assigned",
                      "acceptedWorkerId": workerId,
                    });

                    // ❌ reject other offers
                    final otherOffers = await FirebaseFirestore.instance
                        .collection("offers")
                        .where("taskId", isEqualTo: taskId)
                        .where("status", isEqualTo: "pending")
                        .get();

                    for (final doc in otherOffers.docs) {
                      if (doc.id != offerId) {
                        batch.update(doc.reference, {"status": "rejected"});
                      }
                    }

                    // ✅ create booking
                    batch.set(bookingRef, {
                      "bookingId": bookingRef.id,
                      "customerId": customerId,
                      "workerId": workerId,
                      "taskId": taskId,
                      "status": "accepted",
                      "createdAt": FieldValue.serverTimestamp(),
                      "customerCompleted": false,
                      "workerCompleted": false,
                    });

                    try {
                      await batch.commit();

                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingTrackingScreen(
                            bookingId: bookingRef.id,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },

                  child: const Text("HIRE NOW"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}