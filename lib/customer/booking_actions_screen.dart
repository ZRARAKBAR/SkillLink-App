import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/shared/chat_screen.dart';
import 'payment_screen.dart';
import 'rating_screen.dart';

class BookingActionsScreen extends StatefulWidget {
  final String bookingId;
  final String workerId;
  final String customerId;

  const BookingActionsScreen({
    super.key,
    required this.bookingId,
    required this.workerId,
    required this.customerId,
  });

  @override
  State<BookingActionsScreen> createState() => _BookingActionsScreenState();
}

class _BookingActionsScreenState extends State<BookingActionsScreen> {
  final Color primaryBlack = const Color(0xFF121212);

  Future<void> _updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(widget.bookingId)
        .update({"status": status});
  }

  Stream<DocumentSnapshot> get bookingStream => FirebaseFirestore.instance
      .collection("bookings")
      .doc(widget.bookingId)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: primaryBlack,
        title: const Text("Booking Control Center"),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: bookingStream,
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Booking not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = (data["status"] ?? "pending").toString();
          final budget = data["budget"] ?? "0";

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ================= STATUS =================
              _statusCard(status),

              const SizedBox(height: 20),

              // ================= ACTIONS =================
              _actions(status, budget),
            ],
          );
        },
      ),
    );
  }

  // ================= STATUS CARD =================
  Widget _statusCard(String status) {
    Color color;

    switch (status) {
      case "accepted":
        color = Colors.green;
        break;
      case "in_progress":
        color = Colors.blue;
        break;
      case "completed":
        color = Colors.purple;
        break;
      case "cancelled":
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Booking Status",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _actions(String status, String budget) {
    return Column(
      children: [

        // CHAT
        if (status == "accepted" || status == "in_progress")
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text("Open Chat"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    bookingId: widget.bookingId,
                    receiverId: widget.workerId,
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 10),

        // START JOB (worker/admin trigger)
        if (status == "accepted")
          ElevatedButton(
            onPressed: () => _updateStatus("in_progress"),
            child: const Text("Start Job"),
          ),

        const SizedBox(height: 10),

        // COMPLETE JOB
        if (status == "in_progress")
          ElevatedButton(
            onPressed: () => _updateStatus("completed"),
            child: const Text("Complete Job"),
          ),

        const SizedBox(height: 10),

        // PAYMENT
        if (status == "completed")
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    bookingId: widget.bookingId,
                    amount: budget.toString(),
                  ),
                ),
              );
            },
            child: const Text("Proceed Payment"),
          ),

        const SizedBox(height: 10),

        // RATING
        if (status == "completed")
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    bookingId: widget.bookingId,
                    workerId: widget.workerId,
                  ),
                ),
              );
            },
            child: const Text("Rate Worker"),
          ),

        const SizedBox(height: 10),

        // CANCEL
        if (status == "pending")
          TextButton(
            onPressed: () => _updateStatus("cancelled"),
            child: const Text(
              "Cancel Booking",
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}