import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skilllink_app/customer/view_worker_profile_screen.dart';

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  static const Color primaryBlack = Color(0xFF121212);
  static const Color inDriveGreen = Color(0xFFC6FF00);

  @override
  Widget build(BuildContext context) {
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
        stream: FirebaseFirestore.instance.collection("offers").snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No offers available"));
          }

          final offers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final doc = offers[index];
              final data = (doc.data() as Map<String, dynamic>?) ?? {};

              return _buildOfferCard(context, data, doc.id);
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [

          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF121212),
                child: Icon(Icons.person, color: Color(0xFFC6FF00)),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["workerName"] ?? "Worker",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(
                      "⭐ ${data["rating"] ?? "4.9"} (Verified Worker)",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Text(
                "Rs. ${data["price"] ?? "0"}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            data["message"] ?? "No message",
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),

          const SizedBox(height: 15),

          Row(
            children: [

              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ViewWorkerProfileScreen(
                          workerId: data["workerId"] ?? "",
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
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("offers")
                        .doc(offerId)
                        .update({
                      "status": "accepted",
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlack,
                    foregroundColor: inDriveGreen,
                  ),
                  child: const Text("HIRE NOW"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}