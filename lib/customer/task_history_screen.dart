import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'task_details_screen.dart';
import 'booking_tracking_screen.dart';

class TaskHistoryScreen extends StatefulWidget {
  final String customerId;

  const TaskHistoryScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<TaskHistoryScreen> createState() =>
      _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  final Color primary = const Color(0xFFC6FF00);
  final Color dark = const Color(0xFF121212);

  Stream<QuerySnapshot> _getTasks() {
    return FirebaseFirestore.instance
        .collection("bookings")
        .where("customerId", isEqualTo: widget.customerId)
        .orderBy("updatedAt", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: dark,
        title: const Text("Task History"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _getTasks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No tasks found"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
              docs[index].data() as Map<String, dynamic>;

              final String bookingId = docs[index].id;
              final String status =
                  data["status"] ?? "pending";
              final String category =
                  data["category"] ?? "Service";
              final String workerName =
                  data["workerName"] ?? "Worker";
              final String budget =
                  data["budget"]?.toString() ?? "0";

              return _taskCard(
                context,
                bookingId,
                status,
                category,
                workerName,
                budget,
              );
            },
          );
        },
      ),
    );
  }

  Widget _taskCard(
      BuildContext context,
      String bookingId,
      String status,
      String category,
      String workerName,
      String budget,
      ) {
    Color statusColor;

    switch (status) {
      case "completed":
        statusColor = Colors.green;
        break;
      case "cancelled":
        statusColor = Colors.red;
        break;
      case "in_progress":
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text("Worker: $workerName"),
          Text("Budget: Rs. $budget"),

          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    foregroundColor: primary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingTrackingScreen(
                          bookingId: bookingId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Track"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsScreen(
                          bookingId: bookingId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Details"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}