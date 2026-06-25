import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skilllink_app/customer/booking_tracking_screen.dart';

import 'package:skilllink_app/worker/worker_tracking_screen.dart';
class WorkerActiveJobScreen extends StatelessWidget {
  const WorkerActiveJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workerId = FirebaseAuth.instance.currentUser?.uid;

    if (workerId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in again'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Jobs'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('workerId', isEqualTo: workerId)
            .where(
          'status',
          // 1. THE FIX: Added 'in_progress' to this array so it doesn't disappear!
          whereIn: ['accepted', 'started', 'in_progress'],
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load jobs'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final jobs = snapshot.data?.docs ?? [];

          if (jobs.isEmpty) {
            return const Center(
              child: Text('No active jobs'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final doc = jobs[index];
              final data = doc.data() as Map<String, dynamic>;

              final bookingId = doc.id;
              final title = data['serviceTitle']?.toString() ?? 'Untitled Job';
              final customer = data['customerName']?.toString() ?? 'Customer';
              final budget = data['budget']?.toString() ?? '0';
              final status = data['status']?.toString() ?? 'accepted';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Customer: $customer'),
                      const SizedBox(height: 8),
                      Text(
                        'Budget: Rs. $budget',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(status.toUpperCase()),
                        backgroundColor: status == 'in_progress'
                            ? Colors.blue[100]
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // 2. LOGIC TWEAK: Show START JOB only if accepted/started
                          if (status == 'accepted' || status == 'started')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("bookings")
                                      .doc(bookingId)
                                      .update({"status": "in_progress"});

                                  // Check if context is mounted before navigating after an async gap
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingTrackingScreen(
                                          bookingId: bookingId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text("START JOB"),
                              ),
                            ),

                          // 3. LOGIC TWEAK: If already in progress, show TRACK/CHAT instead
                          if (status == 'in_progress')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      // CHANGED THIS LINE
                                      builder: (_) => WorkerTrackingScreen(
                                        bookingId: bookingId,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF121212),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("TRACK / CHAT"),
                              ),
                            ),
                          const SizedBox(width: 12),

                          // COMPLETE BUTTON
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(bookingId)
                                    .update({
                                  'status': 'completed',
                                  'completedAt': FieldValue.serverTimestamp(),
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC6FF00), // Your accent color
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('COMPLETE'),
                            ),
                          ),
                        ],
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