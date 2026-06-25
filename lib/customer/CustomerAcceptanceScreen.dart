import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerAcceptanceScreen extends StatelessWidget {
  final String offerId;
  final String taskId;
  final String workerId;
  final String price;

  const CustomerAcceptanceScreen({
    super.key,
    required this.offerId,
    required this.taskId,
    required this.workerId,
    required this.price,
  });

  Future<void> acceptOffer(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();

    final bookingRef =
    FirebaseFirestore.instance.collection("bookings").doc();

    // 1. Create booking
    batch.set(bookingRef, {
      "taskId": taskId,
      "workerId": workerId,
      "customerId": FirebaseAuth.instance.currentUser!.uid,
      "price": price,
      "status": "accepted",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // 2. Update offer
    batch.update(
      FirebaseFirestore.instance.collection("offers").doc(offerId),
      {"status": "accepted"},
    );

    // 3. Close task
    batch.update(
      FirebaseFirestore.instance.collection("tasks").doc(taskId),
      {"status": "assigned"},
    );

    await batch.commit();

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Worker Hired Successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Hiring")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Do you want to hire this worker?",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => acceptOffer(context),
              child: Text("Confirm Hire - Rs $price"),
            ),
          ],
        ),
      ),
    );
  }
}