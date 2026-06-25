import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Create or get chat room for a booking
  Future<String> getOrCreateChatRoom({
    required String bookingId,
    required String customerId,
    required String workerId,
  }) async {
    final chatRef = _db.collection('chats').doc(bookingId);

    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        "bookingId": bookingId,
        "customerId": customerId,
        "workerId": workerId,
        "createdAt": FieldValue.serverTimestamp(),
        "lastMessage": "",
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }

    return chatRef.id;
  }

  /// Send message
  Future<void> sendMessage({
    required String chatId,
    required String message,
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      "senderId": _uid,
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "type": "text",
    });

    await _db.collection('chats').doc(chatId).update({
      "lastMessage": message,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// Stream messages
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}