import 'package:cloud_firestore/cloud_firestore.dart';
enum TaskStatus {
  open,
  assigned,
  completed,
}
class TaskModel {
  final String id;
  final String title;
  final String description;
  final double budget;
  final TaskStatus status;
  final String category;
  final String customerId;
  final String? workerId;
  final DateTime createdAt;
  final GeoPoint? location;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.status,
    required this.category,
    required this.customerId,
    required this.createdAt,
    this.workerId,
    this.location,
  });

  // -----------------------
  // Firestore → Model
  // -----------------------
  factory TaskModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data['title']?.toString() ?? 'Untitled Task',
      description: data['description']?.toString() ?? '',
      budget: _parseDouble(data['budget']),
      status: _parseStatus(data['status']),
      category: data['category']?.toString() ?? 'General',
      customerId: data['customerId']?.toString() ?? '',
      workerId: data['workerId']?.toString(),

      createdAt: _parseDate(data['createdAt']),

      location: data['location'] is GeoPoint
          ? data['location']
          : null,
    );
  }

  // -----------------------
  // Model → Firestore
  // -----------------------
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'budget': budget,
      'status': status.name,
      'category': category,
      'customerId': customerId,
      'workerId': workerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
    };
  }

  // -----------------------
  // Helpers
  // -----------------------

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

  static TaskStatus _parseStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'assigned':
        return TaskStatus.assigned;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.open;
    }
  }
}