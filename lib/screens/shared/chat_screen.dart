import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String receiverId;
  final String? chatId; // optional backward compatibility

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.receiverId,
    this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || uid.isEmpty) return;

    // Clear UI immediately for a snappy feel
    _controller.clear();

    try {
      await FirebaseFirestore.instance
          .collection("bookings")
          .doc(widget.bookingId)
          .collection("messages")
          .add({
        "text": text,
        "senderId": uid,
        "receiverId": widget.receiverId,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // auto scroll
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("bookings")
                  .doc(widget.bookingId)
                  .collection("messages")
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Check for errors first so it doesn't load infinitely
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Error: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                // 2. Show loading only when actively waiting for data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // 3. Handle empty state gracefully
                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                // 4. Build the chat list
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>? ?? {};
                    final isMe = data["senderId"] == uid;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.black : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data["text"] ?? "",
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT BAR
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}