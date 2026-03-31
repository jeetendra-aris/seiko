import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiko/presentation/providers/auth_provider.dart';
import 'package:spiko/presentation/providers/chat_provider.dart';
import 'package:spiko/presentation/screens/calls/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({super.key, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();

  Future<void> startCall({required bool isVideo}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final callDoc = FirebaseFirestore.instance.collection('calls').doc();
    final callId = callDoc.id;

    await callDoc.set({
      'callId': callId,
      'callerId': authProvider.user!.uid,
      'receiverId': widget.receiverId,
      'type': isVideo ? 'video' : 'audio',
      'status': 'calling',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callId: callId,
          isCaller: true,
          receiverId: widget.receiverId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    // ✅ THIS IS YOUR CALL ID
    final chatId = "${authProvider.user!.uid}_${widget.receiverId}";

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(child: Icon(Icons.person)),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User Name", style: TextStyle(fontSize: 16)),
                Text("Online", style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => startCall(isVideo: true),
            icon: const Icon(Icons.videocam),
          ),
          IconButton(
            onPressed: () => startCall(isVideo: false),
            icon: const Icon(Icons.call),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder(
              stream: chatProvider.getMessages(chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: msg.senderId == authProvider.user!.uid ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.senderId == authProvider.user!.uid ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 5,
                  color: Colors.black12,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (messageController.text.trim().isEmpty) return;

                      chatProvider.sendMessage(
                        chatId: chatId, // ✅ FIXED
                        senderId: authProvider.user!.uid,
                        receiverId: widget.receiverId,
                        text: messageController.text.trim(),
                      );

                      messageController.clear();
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
