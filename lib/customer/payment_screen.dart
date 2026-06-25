import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatelessWidget {
  final String bookingId;
  final String amount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Amount: Rs. $amount"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("payments")
                    .add({
                  "bookingId": bookingId,
                  "amount": amount,
                  "status": "paid",
                });

                await FirebaseFirestore.instance
                    .collection("bookings")
                    .doc(bookingId)
                    .update({"status": "paid"});

                Navigator.pop(context);
              },
              child: const Text("Pay Now"),
            )
          ],
        ),
      ),
    );
  }
}