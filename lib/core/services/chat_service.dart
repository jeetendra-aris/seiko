import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spiko/data/models/chat_model.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chatId
  String getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? "${uid1}_$uid2" : "${uid2}_$uid1";
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final messageId = const Uuid().v4();

    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
    );

    // Save message
    await _firestore.collection('messages').doc(chatId).collection('chat').doc(messageId).set(message.toMap());

    // Update chat list
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': text,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  // Stream messages (REAL-TIME)
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore.collection('messages').doc(chatId).collection('chat').orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
    });
  }

  Stream<List<ChatModel>> getUserChats(String uid) {
    return _firestore.collection('chats').where('participants', arrayContains: uid).orderBy('updatedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromMap(doc.id, doc.data())).toList();
    });
  }
}
