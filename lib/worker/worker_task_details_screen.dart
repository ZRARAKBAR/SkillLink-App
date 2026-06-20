import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'send_offer_screen.dart';

class WorkerTaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const WorkerTaskDetailsScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<WorkerTaskDetailsScreen> createState() =>
      _WorkerTaskDetailsScreenState();
}

class _WorkerTaskDetailsScreenState extends State<WorkerTaskDetailsScreen> {
  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);

  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String formatLocation(dynamic location) {
    if (location is GeoPoint) {
      return "${location.latitude}, ${location.longitude}";
    }
    return location?.toString() ?? "Not specified";
  }
  @override
  Widget build(BuildContext context) {
    final task = widget.taskData;

    final List<dynamic> rawTags = task['tags'] ?? [];
    final List<String> tags = rawTags.map((e) => e.toString()).toList();

    final List<dynamic> images = task['images'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        title: const Text("Task Details"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= TITLE =================
            Text(
              task['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ================= CATEGORY + BUDGET =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task['category'] ?? 'General',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "Rs. ${task['budget'] ?? task['budget_expected'] ?? '0'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= DESCRIPTION =================
            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              task['description'] ?? 'No description provided.',
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),

            const SizedBox(height: 20),

            // ================= LOCATION =================
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 5),
        Text(formatLocation(task['location'])),
            ]),

            const SizedBox(height: 10),

            // ================= TYPE =================
            Row(
              children: [
                const Icon(Icons.work_outline, size: 18),
                const SizedBox(width: 5),
                Text(task['type'] ?? 'Fixed'),
              ],
            ),

            const SizedBox(height: 20),

            // ================= TAGS =================
            if (tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // ================= IMAGES =================
            if (images.isNotEmpty) ...[
              const Text(
                "Images",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],

            // ================= SEND OFFER BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlack,
                  foregroundColor: inDriveGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final existing = await FirebaseFirestore.instance
                      .collectionGroup('offers')
                      .where('workerId', isEqualTo: _currentUid)
                      .where('taskId', isEqualTo: widget.taskId)
                      .get();

                  if (existing.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You already applied for this task"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SendOfferScreen(),
                    ),
                  );
                },
                child: const Text(
                  "SEND OFFER",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}