import 'package:cloud_firestore/cloud_firestore.dart';

class BookingActions {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Accept booking (worker side)
  Future<void> acceptBooking(String bookingId, String workerId) async {
    await _db.collection('bookings').doc(bookingId).update({
      "status": "accepted",
      "workerId": workerId,
      "acceptedAt": FieldValue.serverTimestamp(),
    });
  }

  /// Start job
  Future<void> startJob(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      "status": "in_progress",
      "startedAt": FieldValue.serverTimestamp(),
    });
  }

  /// Complete job
  Future<void> completeJob(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      "status": "completed",
      "completedAt": FieldValue.serverTimestamp(),
    });
  }

  /// Cancel job
  Future<void> cancelJob(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      "status": "cancelled",
      "cancelledAt": FieldValue.serverTimestamp(),
    });
  }
}