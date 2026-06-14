import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(workerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: primaryBlack,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    data["fullName"] ?? "Worker",
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
                      // NAME + ROLE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data["fullName"] ?? "",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                data["skills"] ?? "Worker",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFC6FF00),
                            child: Icon(Icons.verified, color: Colors.black),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem("150", "Jobs"),
                          _statItem("4.9", "Rating"),
                          _statItem(
                              "${data["experience"] ?? 0}y", "Exp"),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Bio",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Skilled ${data["skills"] ?? "worker"} with ${data["experience"] ?? 0} years of experience.",
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Address",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        data["address"] ?? "Not available",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),

      // HIRE BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlack,
            foregroundColor: inDriveGreen,
            minimumSize: const Size(double.infinity, 55),
          ),
          onPressed: () async {
            // CREATE BOOKING
            User? user = FirebaseAuth.instance.currentUser;

            await FirebaseFirestore.instance.collection("bookings").add({
              "customerId": user!.uid,
              "workerId": workerId,
              "status": "pending",
              "createdAt": FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Worker Hired!")),
            );
          },
          child: const Text(
            "CONFIRM HIRE",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}