import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final String chatId;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.chatId,
    this.isRead = false,
  });

  // -------------------------
  // Firestore → Model
  // -------------------------
  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['senderId']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      chatId: data['chatId']?.toString() ?? '',
      isRead: _parseBool(data['isRead']),
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  // -------------------------
  // Model → Firestore
  // -------------------------
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'chatId': chatId,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // -------------------------
  // Helpers
  // -------------------------

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return DateTime.now();
  }
}