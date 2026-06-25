import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/shared/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerTrackingScreen extends StatefulWidget {
  final String bookingId;

  const WorkerTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<WorkerTrackingScreen> createState() => _WorkerTrackingScreenState();
}

class _WorkerTrackingScreenState extends State<WorkerTrackingScreen> {
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
        if (status == 'completed') "completedAt": FieldValue.serverTimestamp(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlack,
        title: const Text("Job Tracker", style: TextStyle(color: Colors.white)),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Booking not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String status = (data["status"] ?? "pending").toString();
          final String customerId = data["customerId"] ?? "";
          final String workerId = data["workerId"]?.toString() ?? "";
          final String budget = data["budget"]?.toString() ?? "0";
          final String serviceTitle = data["serviceTitle"]?.toString() ?? "Service";

          // Worker needs the customer's phone number
          final String? bookingCustomerPhone = data["customerPhone"];

          return FutureBuilder<DocumentSnapshot>(
            // FLIPPED LOGIC: Fetch the CUSTOMER'S profile, not the worker's
            future: customerId.isNotEmpty
                ? FirebaseFirestore.instance.collection("users").doc(customerId).get()
                : null,
            builder: (context, customerSnap) {
              final customer = customerSnap.data?.data() as Map<String, dynamic>?;

              final String customerPhone = bookingCustomerPhone ?? (customer != null ? customer["phone"] : "") ?? "";

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statusCard(status),
                  const SizedBox(height: 15),

                  // ================= CUSTOMER INFO =================
                  if (customer != null) _customerCard(customer),
                  const SizedBox(height: 15),

                  // ================= JOB INFO =================
                  _infoCard(serviceTitle, budget, status),
                  const SizedBox(height: 20),

                  // ================= ACTIONS =================
                  _actionButtons(status, workerId, customerId, customerPhone),
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
            "Job Status",
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
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CUSTOMER CARD =================
  Widget _customerCard(Map<String, dynamic> customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryBlack,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer["fullName"] ?? customer["name"] ?? "Customer",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text("Client", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= INFO CARD =================
  Widget _infoCard(String title, String budget, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Job Details", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Service: $title"),
          Text("Payout: Rs. $budget", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= ACTIONS =================
  Widget _actionButtons(String status, String workerId, String customerId, String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CHAT & CALL ROW
        if (status == "accepted" || status == "in_progress")
          Row(
            children: [
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
                    if (customerId.isEmpty || workerId.isEmpty) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          bookingId: widget.bookingId,
                          receiverId: customerId, // Chat goes to the CUSTOMER
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
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
                    if (phone.isEmpty) return;
                    final Uri url = Uri.parse("tel:$phone");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 10),

        // COMPLETE JOB
        if (status == "in_progress")
          ElevatedButton(
            onPressed: _isUpdating ? null : () => _updateStatus("completed"),
            style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: primaryBlack,
                padding: const EdgeInsets.symmetric(vertical: 12)
            ),
            child: _isUpdating
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Mark as Completed"),
          ),
      ],
    );
  }
}