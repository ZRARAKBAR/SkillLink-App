import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String taskId;
  final String customerId;
  final String workerId;
  final String workerName;
  final String status;
  final double price;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.taskId,
    required this.customerId,
    required this.workerId,
    required this.workerName,
    required this.status,
    required this.price,
    required this.createdAt,
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      taskId: data['taskId']?.toString() ?? '',
      customerId: data['customerId']?.toString() ?? '',
      workerId: data['workerId']?.toString() ?? '',
      workerName: data['workerName']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      price: _parseDouble(data['price']),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'customerId': customerId,
      'workerId': workerId,
      'workerName': workerName,
      'status': status,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // -----------------------
  // Helpers (important fix)
  // -----------------------

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}