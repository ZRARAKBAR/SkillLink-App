import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkerJobHistoryScreen extends StatelessWidget {
  const WorkerJobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workerId = FirebaseAuth.instance.currentUser?.uid;

    if (workerId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in again'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('workerId', isEqualTo: workerId)
            .where('status', isEqualTo: 'completed')
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load history'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final jobs = snapshot.data?.docs ?? [];

          if (jobs.isEmpty) {
            return const Center(
              child: Text('No completed jobs yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final data =
              jobs[index].data() as Map<String, dynamic>;

              final title =
                  data['serviceTitle']?.toString() ?? 'Untitled Job';

              final customer =
                  data['customerName']?.toString() ?? 'Customer';

              final budget =
                  data['budget']?.toString() ?? '0';

              final completedAt = data['completedAt'];

              String completedDate = 'Unknown';

              if (completedAt is Timestamp) {
                completedDate = DateFormat(
                  'dd MMM yyyy',
                ).format(completedAt.toDate());
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.check),
                  ),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: $customer'),
                      Text('Completed: $completedDate'),
                    ],
                  ),
                  trailing: Text(
                    'Rs. $budget',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}