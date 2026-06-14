import 'package:cloud_firestore/cloud_firestore.dart';
enum OfferStatus {
  pending,
  accepted,
  rejected,
}
class OfferModel {
  final String id;
  final String taskId;
  final String workerId;
  final String workerName;
  final String customerId;
  final double price;
  final String message;
  final OfferStatus status;
  final DateTime createdAt;

  OfferModel({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.workerName,
    required this.customerId,
    required this.price,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  // Firestore → Model
  factory OfferModel.fromMap(String id, Map<String, dynamic> data) {
    return OfferModel(
      id: id,
      taskId: data['taskId']?.toString() ?? '',
      workerId: data['workerId']?.toString() ?? '',
      workerName: data['workerName']?.toString() ?? 'Worker',
      customerId: data['customerId']?.toString() ?? '',
      price: _parseDouble(data['price']),
      message: data['message']?.toString() ?? '',
      status: _parseStatus(data['status']),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'workerId': workerId,
      'workerName': workerName,
      'customerId': customerId,
      'price': price,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // -------------------------
  // Helpers
  // -------------------------

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static OfferStatus _parseStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'accepted':
        return OfferStatus.accepted;
      case 'rejected':
        return OfferStatus.rejected;
      default:
        return OfferStatus.pending;
    }
  }
}