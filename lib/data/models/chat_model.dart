class ChatModel {
  final String chatId;
  final List participants;
  final String lastMessage;
  final DateTime updatedAt;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      chatId: id,
      participants: map['participants'] ?? [],
      lastMessage: map['lastMessage'] ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? 0,
      ),
    );
  }
}
