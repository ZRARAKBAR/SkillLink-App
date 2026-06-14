import 'package:flutter/material.dart';

class SendOfferScreen extends StatefulWidget {
  const SendOfferScreen({super.key});

  @override
  State<SendOfferScreen> createState() => _SendOfferScreenState();
}

class _SendOfferScreenState extends State<SendOfferScreen> {
  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color bgGrey = const Color(0xFFF5F5F5);

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  void _submitOffer() {
    if (_priceController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price and a message.')),
      );
      return;
    }

    // Show Success Message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Offer Sent! The customer will review your bid.', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: inDriveGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Return to the Worker Dashboard
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryBlack),
        title: Text("Send an Offer", style: TextStyle(color: primaryBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Summary Card
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
                  Text("Fix leaking kitchen sink", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlack)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text("Farid Town, Sahiwal", style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Customer Budget: Rs. 800 - 1000", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "Your Bid Details",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryBlack),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Offer Price (Rs.)',
                prefixIcon: const Icon(Icons.money),
                filled: true,
                fillColor: bgGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: primaryBlack, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Why should they hire you?',
                hintText: 'e.g., I am nearby and can fix this in 30 minutes...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: bgGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: primaryBlack, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 3. Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlack,
                  foregroundColor: inDriveGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _submitOffer,
                child: const Text("SEND OFFER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}