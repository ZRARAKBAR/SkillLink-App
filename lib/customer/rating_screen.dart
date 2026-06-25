import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  final String workerId;

  const RatingScreen({
    super.key,
    required this.bookingId,
    required this.workerId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int stars = 5;
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rate Worker")),
      body: Column(
        children: [
          Slider(
            value: stars.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: "$stars",
            onChanged: (v) => setState(() => stars = v.toInt()),
          ),

          TextField(
            controller: reviewController,
            decoration: const InputDecoration(
              hintText: "Write review...",
            ),
          ),

          ElevatedButton(
            onPressed: () async {
              try {
                // Prevent duplicate ratings for the same booking
                final existing = await FirebaseFirestore.instance
                    .collection("ratings")
                    .where("bookingId", isEqualTo: widget.bookingId)
                    .limit(1)
                    .get();

                if (existing.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("You have already rated this booking."),
                    ),
                  );
                  return;
                }

                // Save rating
                await FirebaseFirestore.instance.collection("ratings").add({
                  "bookingId": widget.bookingId,
                  "workerId": widget.workerId,
                  "stars": stars,
                  "review": reviewController.text.trim(),
                  "createdAt": FieldValue.serverTimestamp(),
                });

                // Get all worker ratings
                final ratingsSnapshot = await FirebaseFirestore.instance
                    .collection("ratings")
                    .where("workerId", isEqualTo: widget.workerId)
                    .get();

                double total = 0;

                for (var doc in ratingsSnapshot.docs) {
                  total += (doc["stars"] as num).toDouble();
                }

                final average = total / ratingsSnapshot.docs.length;

                // Update worker profile
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.workerId)
                    .update({
                  "rating": average,
                  "totalRatings": ratingsSnapshot.docs.length,
                });

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Rating submitted successfully."),
                  ),
                );

                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to submit rating: $e"),
                  ),
                );
              }
            },
            child: const Text("Submit Rating"),
          )
        ],
      ),
    );
  }
}