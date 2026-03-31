import 'package:flutter/material.dart';
import 'package:spiko/data/models/chat_model.dart';

import '../../core/services/chat_service.dart';
import '../../data/models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<MessageModel> messages = [];

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _chatService.getMessages(chatId);
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    await _chatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
    );
  }

  Stream<List<ChatModel>> getChats(String uid) {
    return _chatService.getUserChats(uid);
  }
}
