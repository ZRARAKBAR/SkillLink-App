 import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final bool isVerified;
  final bool isBanned;
  final String? documentUrl;
  final bool? isOnline;
  final Timestamp? lastSeen;
  final GeoPoint? location;
  final List<String>? services;
  final double? rating;
  final String? phoneNumber;
  final String? address;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.isVerified = false,
    this.isBanned = false,
    this.documentUrl,
    this.isOnline = false,
    this.lastSeen,
    this.location,
    this.services,
    this.rating,
    this.phoneNumber,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'documentUrl': documentUrl,
      'isOnline': isOnline ?? false,
      'lastSeen': lastSeen,
      'location': location,
      'services': services ?? [],
      'rating': rating ?? 0.0,
      'phoneNumber': phoneNumber ?? '',
      'address': address ?? '',
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'customer',
      isVerified: map['isVerified'] ?? false,
      isBanned: map['isBanned'] ?? false,
      documentUrl: map['documentUrl']?.toString(),
      isOnline: map['isOnline'] as bool?,
      lastSeen: map['lastSeen'] as Timestamp?,
      location: map['location'] as GeoPoint?,
      services: map['services'] is List
          ? List<String>.from((map['services'] as List).map((x) => x.toString()))
          : null,
      rating: map['rating'] is num ? (map['rating'] as num).toDouble() : null,
      phoneNumber: map['phoneNumber']?.toString(),
      address: map['address']?.toString(),
    );
  }
}