import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/shared/chat_screen.dart';
import 'payment_screen.dart';
import 'rating_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingTrackingScreen extends StatefulWidget {
  final String bookingId;

  const BookingTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  final Color primaryBlack = const Color(0xFF121212);
  final Color accent = const Color(0xFFC6FF00);

  bool _isUpdating = false;



  Future<void> _updateStatus(String status) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection("bookings")
          .doc(widget.bookingId)
          .update({
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _generateChatId(String customerId, String workerId) {
    final ids = [customerId, workerId]..sort();
    return ids.join("_");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlack,
        title: const Text("Booking Tracker", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Booking not found"),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;



          final bool isRated = data["isRated"] ?? false;




          final String status = (data["status"] ?? "pending").toString();
          final String customerId = data["customerId"] ?? "";
          final String workerId = data["workerId"]?.toString() ?? "";
          final String budget = data["budget"]?.toString() ?? "0";
          final String? bookingPhone = data["workerPhone"];


          return FutureBuilder<DocumentSnapshot>(
            future: workerId.isNotEmpty
                ? FirebaseFirestore.instance.collection("users").doc(workerId).get()
                : null,
            builder: (context, workerSnap) {
              final worker = workerSnap.data?.data() as Map<String, dynamic>?;

               final String workerPhone = bookingPhone ?? (worker != null ? worker["phone"] : "") ?? "";

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   _statusCard(status),

                  const SizedBox(height: 15),

                  // ================= WORKER =================
                  if (worker != null) _workerCard(worker),

                  const SizedBox(height: 15),

                  // ================= INFO =================
                  _infoCard(budget, status),

                  const SizedBox(height: 20),

                  // ================= ACTIONS =================
                  _actionButtons(status, workerId, customerId, workerPhone,isRated),
                ],
              );
            },
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
            "Current Status",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
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

  // ================= WORKER =================
  Widget _workerCard(Map<String, dynamic> worker) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent,
            child: const Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker["fullName"] ?? "Worker",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  worker["skills"] ?? "Skilled Worker",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= INFO =================
  Widget _infoCard(String budget, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Booking Details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text("Budget: Rs. $budget"),
          Text("Status: $status"),
        ],
      ),
    );
  }

  // ================= ACTIONS =================
  Widget _actionButtons(String status, String workerId, String customerId, String phone,bool isRated,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CHAT & CALL ROW
        if (status == "accepted" || status == "in_progress")
          Row(
            children: [
              // CHAT
              // CHAT
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (customerId.isEmpty || workerId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Missing chat data"),
                        ),
                      );
                      return;
                    }

                    // --- ADDED LOGIC HERE ---
                    // 1. Get the currently logged-in user
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

                    // 2. Figure out who the OTHER person is
                    // If I am the customer, the receiver is the worker.
                    // If I am not the customer (meaning I'm the worker), the receiver is the customer.
                    final actualReceiverId = (currentUserId == customerId) ? workerId : customerId;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          bookingId: widget.bookingId,
                          receiverId: actualReceiverId, // Pass the dynamic ID here
                        ),
                      ),
                    );
                  },
                ),
              ),

              // CALL
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text("Call"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: primaryBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No phone number found"),
                        ),
                      );
                      return;
                    }

                    final Uri url = Uri.parse("tel:$phone");

                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Could not launch dialer"),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 10),

        // START JOB
        if (status == "accepted")
          ElevatedButton(
            onPressed: _isUpdating ? null : () => _updateStatus("in_progress"),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: _isUpdating
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text("Start Job"),
          ),

        // COMPLETE JOB
        if (status == "in_progress")
          ElevatedButton(
            onPressed: _isUpdating ? null : () => _updateStatus("completed"),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text("Mark Completed"),
          ),

        // PAYMENT
        if (status == "completed")
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    bookingId: widget.bookingId,
                    amount: "1000",
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text("Proceed Payment"),
          ),
        // RATING
          if (status == "completed" && !isRated)
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    bookingId: widget.bookingId,
                    workerId: workerId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
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