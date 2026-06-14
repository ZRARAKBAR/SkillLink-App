import 'package:flutter/material.dart';
import 'package:skilllink_app/customer/post_task_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceName;
  final String description;
  final String imageUrl; // optional

  const ServiceDetailScreen({
    super.key,
    required this.serviceName,
    required this.description,
    this.imageUrl = "",
  });

  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryBlack,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image (optional)
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.handyman,
                  size: 80,
                  color: Colors.grey.shade500,
                ),
              ),

            const SizedBox(height: 20),

            Text(
              serviceName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Average price: Rs. 500 - Rs. 3000 (depends on work)",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlack,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostTaskScreen(
                        initialCategory: serviceName,
                      ),
                    ),
                  );
                },
                child: Text(
                  "POST A TASK",
                  style: TextStyle(color: inDriveGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}