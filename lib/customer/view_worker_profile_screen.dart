import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skilllink_app/customer/booking_tracking_screen.dart';

class ViewWorkerProfileScreen extends StatelessWidget {
  final String workerId;

  const ViewWorkerProfileScreen({
    super.key,
    required this.workerId,
  });

  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(workerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final Map<String, dynamic> data =
        snapshot.data!.data() as Map<String, dynamic>;

        final String fullName =
            data["fullName"]?.toString() ?? "Worker";

        final String skills =
            data["skills"]?.toString() ?? "Worker";

        final String address =
            data["address"]?.toString() ?? "Not available";

        final int experience =
        (data["experience"] is int)
            ? data["experience"]
            : int.tryParse(data["experience"].toString()) ?? 0;

        return Scaffold(
          backgroundColor: Colors.white,

          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: primaryBlack,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    fullName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  background: Container(color: primaryBlack),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                skills,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFC6FF00),
                            child: Icon(
                              Icons.verified,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem("150", "Jobs"),
                          _statItem(
                            ((data["rating"] ?? 0.0) as num)
                                .toStringAsFixed(1),
                            "Rating",
                          ),
                          _statItem("${experience}y", "Exp"),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Bio",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Skilled $skills with $experience years of experience.",
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Address",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        address,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ================= HIRE BUTTON =================
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlack,
                foregroundColor: inDriveGreen,
                minimumSize: const Size(double.infinity, 55),
              ),

              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final bookingRef = FirebaseFirestore.instance
                    .collection("bookings")
                    .doc();

                await bookingRef.set({
                  "customerId": user.uid,
                  "workerId": workerId,
                  "type": "direct",
                  "status": "pending",
                  "createdAt": FieldValue.serverTimestamp(),

                  // tracking + rating support (SAFE ADDITION)
                  "workerName": fullName,
                  "workerPhone": data["phone"] ?? "",
                  "category": skills,
                  "price": data["servicePrice"] ?? 0,
                });

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Worker Hired!")),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingTrackingScreen(
                      bookingId: bookingRef.id,
                    ),
                  ),
                );
              },

              child: const Text(
                "CONFIRM HIRE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}