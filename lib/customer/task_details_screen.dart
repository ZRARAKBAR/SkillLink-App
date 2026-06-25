import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skilllink_app/screens/shared/chat_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String bookingId;

  const TaskDetailsScreen({super.key, required this.bookingId});

  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);

  String _generateChatId(String customerId, String workerId) {
    final ids = [customerId, workerId]..sort();
    return ids.join("_");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Booking not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String workerName = data["workerName"] ?? "Worker";
          final String category = data["category"] ?? "Service";
          final String status = data["status"] ?? "pending";
          final int price = (data["price"] ?? 0);

          final String? phone = data["workerPhone"];
          final String? customerId = data["customerId"];
          final String? workerId = data["workerId"];

          return Stack(
            children: [

              // ================= MAP PLACEHOLDER =================
              Positioned.fill(
                child: Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.map_outlined,
                        size: 100, color: Colors.grey),
                  ),
                ),
              ),

              // ================= BOTTOM SHEET =================
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: primaryBlack,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // drag handle
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ================= WORKER INFO =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                category,
                                style: TextStyle(
                                  color: inDriveGreen.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Rs. $price",
                                style: TextStyle(
                                  color: inDriveGreen,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "Fixed Price",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ================= STATUS (VIEW ONLY) =================
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Text(
                              "Status",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const Spacer(),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: inDriveGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ================= ACTIONS =================
                      Row(
                        children: [

                          // CHAT
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text("CHAT"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.white.withOpacity(0.1),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                if (customerId == null ||
                                    workerId == null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Missing chat data"),
                                    ),
                                  );
                                  return;
                                }

                                final chatId =
                                _generateChatId(
                                    customerId, workerId);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      bookingId: bookingId,
                                      receiverId: workerId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          // CALL
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.call),
                              label: const Text("CALL"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inDriveGreen,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                if (phone == null || phone.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "No phone number found"),
                                    ),
                                  );
                                  return;
                                }

                                final Uri url =
                                Uri.parse("tel:$phone");

                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}