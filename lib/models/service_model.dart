import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final String image;
  final bool isActive;
  final DateTime createdAt;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.isActive = true,
    required this.createdAt,
  });

  // Firestore → Model
  factory Service.fromMap(String id, Map<String, dynamic> data) {
    return Service(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
      isActive: _parseBool(data['isActive']),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // -----------------------
  // Helpers
  // -----------------------

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}