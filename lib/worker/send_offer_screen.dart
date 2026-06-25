import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SendOfferScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const SendOfferScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<SendOfferScreen> createState() => _SendOfferScreenState();
}

class _SendOfferScreenState extends State<SendOfferScreen> {
  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color bgGrey = const Color(0xFFF5F5F5);

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitOffer() async {
    if (_priceController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price and a message.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      final offerData = {
        "workerId": user.uid,
        "price": int.tryParse(_priceController.text) ?? 0,
        "message": _messageController.text,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection("offers").add({
        "taskId": widget.taskId,
        "customerId": widget.taskData["customerId"], // VERY IMPORTANT
        "workerId": user.uid,
        "workerName": user.displayName ?? "Worker",
        "price": int.tryParse(_priceController.text) ?? 0,
        "message": _messageController.text,
        "status": "pending",
        "rating": 4.9,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Offer Sent Successfully!',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: inDriveGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.taskData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryBlack),
        title: Text(
          "Send an Offer",
          style: TextStyle(
            color: primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TASK SUMMARY (UNCHANGED UI)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task["title"] ?? "Task",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        task["category"] ?? "General",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Customer Budget: Rs. ${task["budget"] ?? 0}",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Your Bid Details",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: primaryBlack,
              ),
            ),

            const SizedBox(height: 20),

            // PRICE INPUT (UNCHANGED STYLE)
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Offer Price (Rs.)',
                prefixIcon: const Icon(Icons.money),
                filled: true,
                fillColor: bgGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // MESSAGE INPUT (UNCHANGED STYLE)
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Why should they hire you?',
                hintText:
                'e.g., I am nearby and can fix this in 30 minutes...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: bgGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // SUBMIT BUTTON (UPGRADED ONLY LOGIC)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlack,
                  foregroundColor: inDriveGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isLoading ? null : _submitOffer,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "SEND OFFER",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}